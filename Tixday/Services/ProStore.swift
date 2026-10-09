import Foundation
import Observation
import RevenueCat
import WidgetKit

/// A purchasable Pro option, already formatted for display.
struct ProPackage: Identifiable, Hashable {
    enum Kind {
        case yearly
        case lifetime
        case other
    }

    let id: String
    let kind: Kind
    let price: String
    /// "$0.83" for yearly plans, so the paywall can show a monthly equivalent.
    let pricePerMonth: String?
    /// "7-day free trial", only when the user is eligible.
    let trial: String?
}

/// What Pro unlocks, so the paywall can open on the reason the user hit it.
enum ProFeature: String, Identifiable {
    case unlimitedTickets
    case photos
    case lockScreen

    var id: String { rawValue }
}

/// Pro entitlement state and purchases, backed by RevenueCat.
@MainActor
@Observable
final class ProStore {
    static let entitlementID = "tixday_pro"
    static let freeTicketLimit = TicketAccess.freeLimit

    private(set) var isPro = false {
        didSet { syncWidgetFlag() }
    }
    private(set) var packages: [ProPackage] = []
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    var errorMessage: String?

    private var storePackages: [String: Package] = [:]
    private let isConfigured: Bool

    init() {
        isConfigured = !AppConfig.revenueCatAPIKey.isEmpty
        if isConfigured {
            Purchases.logLevel = .warn
            Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        }
        #if DEBUG
        if Self.forcesProForScreenshots {
            isPro = true
        } else if !isConfigured {
            // `-resetPro`: back to the free tier, for testing the paywall again.
            if CommandLine.arguments.contains("-resetPro") {
                UserDefaults.standard.set(false, forKey: Self.debugProKey)
            }
            isPro = UserDefaults.standard.bool(forKey: Self.debugProKey)
        }
        // Assignments in init don't trigger didSet.
        syncWidgetFlag()
        #endif
    }

    /// Whether a free user may add another ticket; only upcoming tickets count.
    func canAddTicket(upcomingCount: Int) -> Bool {
        isPro || upcomingCount < Self.freeTicketLimit
    }

    /// Mirrors `isPro` into the App Group so the widget shows Lock Screen content or the Pro prompt.
    /// Compares against the stored value, not the previous in-memory one, so a stale flag is always corrected.
    private func syncWidgetFlag() {
        let defaults = AppGroup.defaults
        guard defaults.bool(forKey: AppGroup.proUnlockedKey) != isPro else { return }
        defaults.set(isPro, forKey: AppGroup.proUnlockedKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Loads products and then follows entitlement changes for as long as the caller's task lives.
    func start() async {
        guard isConfigured else {
            loadDebugPackages()
            return
        }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
        await restoreSilentlyAfterInstall()
        await loadOfferings()
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    /// After a fresh install RevenueCat starts with a new anonymous user, so earlier purchases tied to the
    /// Apple ID are invisible until restored. Sync once per install, without the sign-in prompt
    /// `restorePurchases` can show, so returning customers get Pro back automatically.
    private func restoreSilentlyAfterInstall() async {
        // Standard defaults are wiped on uninstall, unlike the App Group, so this runs once per install.
        let key = "didSyncPurchasesAfterInstall"
        guard !isPro, !UserDefaults.standard.bool(forKey: key) else { return }
        if let info = try? await Purchases.shared.syncPurchases() {
            apply(info)
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    func loadOfferings() async {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let available = try await Purchases.shared.offerings().current?.availablePackages ?? []
            storePackages = Dictionary(uniqueKeysWithValues: available.map { ($0.identifier, $0) })
            var result: [ProPackage] = []
            for package in available {
                result.append(await Self.makePackage(package))
            }
            packages = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns true when the purchase unlocked Pro.
    func purchase(_ package: ProPackage) async -> Bool {
        #if DEBUG
        if !isConfigured {
            setDebugPro(true)
            return true
        }
        #endif
        guard let storePackage = storePackages[package.id] else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: storePackage)
            if result.userCancelled { return false }
            apply(result.customerInfo)
            return isPro
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Returns true when an active Pro entitlement was found.
    func restore() async -> Bool {
        guard isConfigured else { return isPro }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
            if !isPro {
                errorMessage = String(localized: "No previous Pro purchase was found for this Apple ID.")
            }
            return isPro
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func apply(_ info: CustomerInfo) {
        #if DEBUG
        if Self.forcesProForScreenshots { return }
        #endif
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
    }

    private static func makePackage(_ package: Package) async -> ProPackage {
        let product = package.storeProduct
        let kind: ProPackage.Kind = switch package.packageType {
        case .annual: .yearly
        case .lifetime: .lifetime
        default: .other
        }

        var trial: String?
        if let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial {
            let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
            if eligibility != .ineligible {
                trial = trialText(intro.subscriptionPeriod)
            }
        }

        return ProPackage(
            id: package.identifier,
            kind: kind,
            price: product.localizedPriceString,
            pricePerMonth: kind == .yearly ? product.localizedPricePerMonth : nil,
            trial: trial
        )
    }

    private static func trialText(_ period: SubscriptionPeriod) -> String {
        let value = period.value
        switch period.unit {
        case .day: return String(localized: "\(value)-day free trial")
        case .week: return String(localized: "\(value * 7)-day free trial")
        case .month: return String(localized: "\(value)-month free trial")
        case .year: return String(localized: "\(value)-year free trial")
        @unknown default: return String(localized: "Free trial")
        }
    }

    // MARK: - Debug products (never compiled into release builds)

    #if DEBUG
    private static let debugProKey = "debug.isPro"
    /// `-proScreenshots`: Pro features on without RevenueCat, for App Store screenshots.
    private static let forcesProForScreenshots = CommandLine.arguments.contains("-proScreenshots")

    var usesDebugProducts: Bool { !isConfigured }

    func setDebugPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.debugProKey)
    }

    private func loadDebugPackages() {
        packages = [
            ProPackage(id: "debug_yearly", kind: .yearly, price: "$9.99", pricePerMonth: "$0.83", trial: String(localized: "7-day free trial")),
            ProPackage(id: "debug_lifetime", kind: .lifetime, price: "$24.99", pricePerMonth: nil, trial: nil),
        ]
    }
    #else
    private func loadDebugPackages() {}
    #endif
}
