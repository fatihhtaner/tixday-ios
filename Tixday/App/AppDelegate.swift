import Observation
import UIKit
import UserNotifications

/// A link waiting to be opened by the home screen: from a widget, a reminder, or a URL.
@MainActor
@Observable
final class LinkRouter {
    static let shared = LinkRouter()
    var pending: DeepLink?
}

/// Opens the ticket behind a tapped reminder, and shows reminders while the app is open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            let value = response.notification.request.content.userInfo["ticketID"] as? String,
            let id = UUID(uuidString: value)
        else { return }
        await MainActor.run { LinkRouter.shared.pending = .ticket(id) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
