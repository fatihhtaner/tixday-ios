import Foundation
import SwiftData

/// The SwiftData store, kept in the App Group so the widget extension can read it, and synced to iCloud by the app.
enum SharedStore {
    static let cloudContainerID = "iCloud.com.ibrahimfatihtaner.tixday"

    /// The app syncs through the user's private iCloud database; the widget only reads the local copy.
    /// Without iCloud (signed out, or the store can't be opened with it) the same local store is used.
    static func makeContainer(syncWithICloud: Bool = false) -> ModelContainer {
        let group = ModelConfiguration.GroupContainer.identifier(AppGroup.id)
        createStoreDirectoryIfNeeded()
        var configurations: [ModelConfiguration] = []
        if syncWithICloud {
            configurations.append(ModelConfiguration(groupContainer: group, cloudKitDatabase: .private(cloudContainerID)))
        }
        configurations.append(ModelConfiguration(groupContainer: group, cloudKitDatabase: .none))

        for configuration in configurations {
            do {
                return try ModelContainer(for: TicketEvent.self, configurations: configuration)
            } catch {
                #if DEBUG
                print("SharedStore: could not open store (cloudKit: \(configuration.cloudKitDatabase)): \(error)")
                #endif
            }
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
