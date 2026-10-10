import Foundation

/// The language chosen in Settings, shared with the widget through the App Group.
/// Empty means "follow iOS". Applies at once: the app sets `locale` in the environment for SwiftUI
/// and passes `bundle: .app` to `String(localized:)`.
enum AppLanguage {
    static let key = "appLanguage"

    /// The languages Tixday is translated into, in the order the picker shows them.
    static let supported = ["en", "tr", "de", "fr", "es", "it", "pt-BR", "ja", "ko", "zh-Hans", "ru", "ar"]

    /// The chosen language code, or nil to follow iOS.
    static var override: String? {
        let code = AppGroup.defaults.string(forKey: key) ?? ""
        return supported.contains(code) ? code : nil
    }

    /// The best match for the iPhone's own language list.
    static var system: String {
        Bundle.main.preferredLocalizations.first.flatMap { code in supported.contains(code) ? code : nil } ?? "en"
    }

    /// The language the app is showing right now.
    static var current: String {
        override ?? system
    }

    /// For dates and other formatting: the app's language with the device's region.
    static var locale: Locale {
        var components = Locale.Components(identifier: current)
        components.region = Locale.current.region
        return Locale(components: components)
    }

    static var isRightToLeft: Bool {
        Locale.Language(identifier: current).characterDirection == .rightToLeft
    }

    /// A language's own name for itself ("Türkçe", "Deutsch").
    static func nativeName(_ code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code)?.capitalized(with: locale) ?? code
    }

    /// The chosen language's translations. SwiftUI `Text` follows the `locale` environment on its own;
    /// `String(localized:)` does not, so those calls pass `bundle: .app`.
    static var bundle: Bundle {
        let code = current
        lock.lock()
        defer { lock.unlock() }
        if let cached = bundles[code] { return cached }
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { return .main }
        bundles[code] = bundle
        return bundle
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var bundles: [String: Bundle] = [:]
}

extension Bundle {
    /// Strings in the app's chosen language, for `String(localized:bundle:)`.
    static var app: Bundle { AppLanguage.bundle }
}
