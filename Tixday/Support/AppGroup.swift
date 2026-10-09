import Foundation

enum AppGroup {
    static let id = "group.com.ibrahimfatihtaner.tixday"

    /// Settings shared with the widget extension.
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }

    /// Mirrors the Pro entitlement so the widget can unlock Lock Screen sizes.
    static let proUnlockedKey = "proUnlocked"
}
