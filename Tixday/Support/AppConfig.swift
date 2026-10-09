import Foundation

enum AppConfig {
    /// RevenueCat public SDK key. Public keys are meant to ship inside the app.
    /// Debug builds use the RevenueCat Test Store key, which must never ship;
    /// release builds use the App Store key (`appl_…`) from RevenueCat → Project → API keys.
    /// Release stays empty until the App Store app is added in RevenueCat; purchases then fall back to nothing.
    #if DEBUG
    static let revenueCatAPIKey = "test_VsGCYuApzaeGgQVwnOsuBuoNkDa"
    #else
    static let revenueCatAPIKey = ""
    #endif

    // TODO: publish the support site (tixday.app or GitHub Pages) and point these at it.
    static let privacyPolicyURL = URL(string: "https://fatihhtaner.github.io/tixday-site/privacy.html")!
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
