import CloudKit
import CoreData
import Foundation
import Observation

/// Watches whether tickets are actually reaching iCloud, so the user isn't silently unprotected
/// (signed out of iCloud, iCloud turned off for Tixday, or iCloud storage full).
///
/// SwiftData syncs through NSPersistentCloudKitContainer, which reports every setup/import/export as an
/// `eventChangedNotification`; failed exports carry the CloudKit error.
@MainActor
@Observable
final class SyncMonitor {
    enum State: Equatable {
        case checking
        /// Syncing normally; the date of the last successful sync, if any.
        case active(lastSync: Date?)
        /// No iCloud account on the device, or iCloud is turned off for Tixday.
        case unavailable
        /// The user's iCloud storage is full, so changes can't be uploaded.
        case storageFull
        /// Another error; changes stay on this device and are retried.
        case failing
    }

    private(set) var state: State = .checking
    /// True while a check the user asked for is running.
    private(set) var isRetrying = false

    private static let lastSyncKey = "sync.lastSuccess"
    private let containerID: String
    private var lastSync: Date? {
        didSet { UserDefaults.standard.set(lastSync, forKey: Self.lastSyncKey) }
    }

    init(containerID: String = SharedStore.cloudContainerID) {
        self.containerID = containerID
        lastSync = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
    }

    /// Follows account changes and sync events for as long as the caller's task lives.
    func start() async {
        await refreshAccountStatus()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await _ in NotificationCenter.default.notifications(named: .CKAccountChanged) {
                    await self.refreshAccountStatus()
                }
            }
            group.addTask { @MainActor in
                let name = NSPersistentCloudKitContainer.eventChangedNotification
                for await note in NotificationCenter.default.notifications(named: name) {
                    let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                    guard let event = note.userInfo?[key] as? NSPersistentCloudKitContainer.Event else { continue }
                    self.handle(event)
                }
            }
        }
    }

    /// "Try again" in Settings. There's no public way to force a CloudKit upload, so this re-checks the
    /// account and waits briefly for the sync the system retries on its own; a successful upload during
    /// the wait clears the problem through `handle(_:)`.
    func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }
        await refreshAccountStatus()
        try? await Task.sleep(for: .seconds(2))
    }

    func refreshAccountStatus() async {
        let status = try? await CKContainer(identifier: containerID).accountStatus()
        if status != .available {
            state = .unavailable
        } else if state == .unavailable || state == .checking {
            state = .active(lastSync: lastSync)
        }
    }

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        guard event.endDate != nil else { return }  // Only finished events say how it went.
        if event.succeeded {
            if event.type != .setup { lastSync = event.endDate }
            // Downloads still work when iCloud is full; only a successful upload clears an upload problem.
            let uploadProblem = state == .storageFull || state == .failing
            if event.type == .export || !uploadProblem {
                state = .active(lastSync: lastSync)
            }
        } else if let error = event.error {
            state = Self.state(for: error) ?? state
        }
    }

    /// Maps a sync error to what the user should see; nil keeps the current state (e.g. a passing hiccup).
    nonisolated static func state(for error: Error) -> State? {
        let codes = cloudKitCodes(in: error)
        if codes.contains(.quotaExceeded) { return .storageFull }
        if codes.contains(.notAuthenticated) { return .unavailable }
        let transient: Set<CKError.Code> = [.networkUnavailable, .networkFailure, .serviceUnavailable,
                                            .requestRateLimited, .zoneBusy, .operationCancelled]
        if !codes.isEmpty && codes.isSubset(of: transient) { return nil }
        return .failing
    }

    /// CloudKit error codes in an error, including per-item errors of a partial failure and
    /// errors wrapped by Core Data.
    nonisolated static func cloudKitCodes(in error: Error) -> Set<CKError.Code> {
        var codes: Set<CKError.Code> = []
        var pending: [Error] = [error]
        while let next = pending.popLast() {
            let nsError = next as NSError
            if nsError.domain == CKError.errorDomain, let code = CKError.Code(rawValue: nsError.code) {
                codes.insert(code)
                if let partial = nsError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
                    pending.append(contentsOf: partial.values)
                }
            }
            if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                pending.append(underlying)
            }
        }
        return codes
    }
}
