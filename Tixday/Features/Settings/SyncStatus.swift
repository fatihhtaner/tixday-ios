import SwiftUI

/// How the iCloud state reads in Settings.
extension SyncMonitor.State {
    var title: LocalizedStringKey {
        switch self {
        case .checking: "Checking…"
        case .active: "On"
        case .unavailable: "Off"
        case .storageFull: "Storage full"
        case .failing: "Not syncing"
        }
    }

    var symbol: String {
        switch self {
        case .checking: "icloud"
        case .active: "checkmark.icloud"
        case .unavailable: "icloud.slash"
        case .storageFull, .failing: "exclamationmark.icloud"
        }
    }

    var isProblem: Bool {
        switch self {
        case .unavailable, .storageFull, .failing: true
        case .checking, .active: false
        }
    }

    /// What the user should know or do, in one sentence.
    var explanation: LocalizedStringKey {
        switch self {
        case .checking:
            "Your tickets are backed up to your private iCloud and appear on your other devices."
        case .active(let lastSync):
            if let lastSync {
                "Your tickets are backed up to your private iCloud. Last synced \(lastSync.formatted(.relative(presentation: .named).locale(AppLanguage.locale)))."
            } else {
                "Your tickets are backed up to your private iCloud and appear on your other devices."
            }
        case .unavailable:
            "Sign in to iCloud and turn on iCloud for Tixday in the Settings app to back up your tickets. Until then they're stored only on this iPhone."
        case .storageFull:
            "Your iCloud storage is full, so new changes aren't backed up. They're safe on this iPhone and will sync once you free up space."
        case .failing:
            "Changes couldn't be backed up yet. They're safe on this iPhone and Tixday will keep trying."
        }
    }
}
