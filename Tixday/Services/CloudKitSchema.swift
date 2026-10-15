#if DEBUG
import CoreData
import SwiftData

/// Creates the full CloudKit schema (every record type and field, including ones that are still empty)
/// in the Development environment, so it can be deployed to Production in the CloudKit Console.
///
/// Run a Debug build once with the `-initCloudKitSchema` launch argument on a device signed in to iCloud
/// whenever the model changes. SwiftData has no API for this, so it goes through Core Data with the same model.
enum CloudKitSchema {
    static func initialize() {
        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [TicketEvent.self]) else {
            print("CloudKitSchema: could not build the managed object model")
            return
        }
        // A throwaway store, so the app's real store is never opened twice.
        let url = FileManager.default.temporaryDirectory.appending(path: "schema-init.sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: SharedStore.cloudContainerID)
        description.shouldAddStoreAsynchronously = false

        let container = NSPersistentCloudKitContainer(name: "SchemaInit", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError {
            print("CloudKitSchema: could not load the store: \(loadError)")
            return
        }
        do {
            try container.initializeCloudKitSchema()
            print("CloudKitSchema: schema initialized in \(SharedStore.cloudContainerID)")
        } catch {
            print("CloudKitSchema: failed: \(error)")
        }
        for store in container.persistentStoreCoordinator.persistentStores {
            try? container.persistentStoreCoordinator.remove(store)
        }
        try? FileManager.default.removeItem(at: url)
    }
}
#endif
