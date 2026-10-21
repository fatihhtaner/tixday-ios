#if DEBUG
import Foundation

/// `-screenshotScreen <name>`: opens one screen, or plays a scripted flow, for App Store screenshots
/// and tutorial videos. Debug builds only.
enum DemoMode {
    static var screen: String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "-screenshotScreen"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    /// The tutorial video's flow: from an empty home, create a Tokyo trip and save it.
    static var createsTicket: Bool { screen == "create-demo" }

    /// Episode 2: after the birthday is saved, home opens its details to show "Every year".
    static var opensSavedTicket: Bool { screen == "birthday-demo" }
}
#endif
