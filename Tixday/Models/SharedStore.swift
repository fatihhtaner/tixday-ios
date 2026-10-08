import Foundation
import SwiftData

/// The SwiftData store, kept in the App Group so the widget extension can read it.
enum SharedStore {
    static func makeContainer() -> ModelContainer {
        createStoreDirectoryIfNeeded()
        let configuration = ModelConfiguration(
            groupContainer: .identifier(AppGroup.id),
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: TicketEvent.self, configurations: configuration)
        } catch {
            #if DEBUG
            print("SharedStore: could not open the App Group store: \(error)")
            #endif
        }
        // Without the App Group entitlement (e.g. a misconfigured build) fall back to the app's own container.
        do {
            return try ModelContainer(for: TicketEvent.self)
        } catch {
            fatalError("Could not create the data store: \(error)")
        }
    }

    /// On a fresh install the App Group has no `Library/Application Support` yet; Core Data creates it
    /// itself, but only after logging a long block of errors. Creating it first keeps the logs clean.
    private static func createStoreDirectoryIfNeeded() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id) else {
            return
        }
        let directory = groupURL.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
