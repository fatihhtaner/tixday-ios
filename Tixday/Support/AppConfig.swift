import Foundation

enum AppConfig {
    /// RevenueCat public SDK key. Public keys are meant to ship inside the app.
    /// Debug builds use the RevenueCat Test Store key, which must never ship;
    /// release builds use the App Store key (`appl_…`) from RevenueCat → Project → API keys.
    #if DEBUG
    static let revenueCatAPIKey = "test_VsGCYuApzaeGgQVwnOsuBuoNkDa"
    #else
    static let revenueCatAPIKey = "appl_gvyDsCPbFeQywruQcNUZOinmALN"
    #endif

    static var privacyPolicyURL: URL { sitePage("privacy.html") }
    static var supportURL: URL { sitePage("support.html") }
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    static let supportEmail = "ibrahimfatihtanerbsns@gmail.com"

    /// A new mail to support, with the app version and iOS version filled in.
    static func supportMailURL(version: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Tixday"),
            URLQueryItem(name: "body", value: "\n\n\(version), iOS \(ProcessInfo.processInfo.operatingSystemVersionString)"),
        ]
        return components.url!
    }

    /// The website page in the language the app is running in (English lives at the root).
    /// Source: `tools/build_site.py`, published from the fatihhtaner/tixday-site repository.
    private static func sitePage(_ page: String) -> URL {
        let base = "https://fatihhtaner.github.io/tixday-site/"
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let folder = language == "en" ? "" : language.lowercased() + "/"
        return URL(string: base + folder + page)!
    }
}
