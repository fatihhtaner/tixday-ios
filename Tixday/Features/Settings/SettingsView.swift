import StoreKit
import SwiftData
import SwiftUI
import UserNotifications

/// Pro status and purchases, reminder preferences, help links and the version.
struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [TicketEvent]

    @AppStorage(ReminderSettings.enabledKey) private var remindersEnabled = true
    @AppStorage(ReminderSettings.timeKey) private var reminderMinutes = ReminderSettings.defaultMinutes
    @State private var notificationStatus: UNAuthorizationStatus?
    @State private var isShowingPaywall = false
    @State private var isManagingSubscription = false
    @State private var restoreMessage: String?

    private var upcomingCount: Int {
        events.filter { DayCount.days(until: $0.date) >= 0 }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Settings")
                    .font(Theme.display(28))
                    .padding(.top, 20)

                section("Pro") { proCard }
                section("Reminders") { remindersCard }
                section("Help") { helpCard }

                Text(versionText)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background { PosterBackdrop(kind: .holiday) }
        .overlay(alignment: .topTrailing) {
            Button("Close", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 36, height: 36)
                .glassBackground(in: Circle(), interactive: true)
                .padding(16)
        }
        .environment(\.colorScheme, .dark)
        .tint(.white)
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .alert("Restore Purchases", isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .task(id: scenePhase) {
            // Re-read when coming back from iOS Settings.
            if scenePhase == .active { await refreshNotificationStatus() }
        }
    }

    // MARK: - Pro

    private var proCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                icon(pro.isPro ? "checkmark.seal.fill" : "sparkles")
                VStack(alignment: .leading, spacing: 2) {
                    Text(pro.isPro ? "Pro is active" : "Free plan")
                        .font(.body.weight(.semibold))
                    Text(proDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)

            if !pro.isPro {
                Button {
                    isShowingPaywall = true
                } label: {
                    Text("Get Tixday Pro")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            if pro.isPro && !pro.isLifetime {
                divider
                row("Manage Subscription", symbol: "creditcard") { isManagingSubscription = true }
            }
            divider
            row("Restore Purchases", symbol: "arrow.clockwise", isBusy: pro.isPurchasing) { restore() }
        }
        .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var proDetail: String {
        if pro.isLifetime {
            return String(localized: "Lifetime. Thanks for supporting Tixday!")
        }
        if pro.isPro, let date = pro.expirationDate {
            let day = date.formatted(date: .long, time: .omitted)
            return pro.willRenew ? String(localized: "Renews on \(day)") : String(localized: "Ends on \(day)")
        }
        let used = min(upcomingCount, ProStore.freeTicketLimit)
        return String(localized: "\(used) of \(ProStore.freeTicketLimit) free tickets used")
    }

    private func restore() {
        Task {
            if await pro.restore() {
                restoreMessage = String(localized: "Tixday Pro is active again.")
            } else {
                restoreMessage = pro.errorMessage
                pro.errorMessage = nil
            }
        }
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $remindersEnabled.animation(.snappy)) {
                HStack(spacing: 14) {
                    icon("bell.badge")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Countdown reminders")
                            .font(.body.weight(.semibold))
                        Text("A month, a week and a day before, and on the day.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.green)
            .padding(16)
            .onChange(of: remindersEnabled) { _, isOn in
                if isOn { Task { await requestPermission() } }
            }

            if remindersEnabled {
                divider
                DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                    HStack(spacing: 14) {
                        icon("clock")
                        Text("Time").font(.body.weight(.semibold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if notificationStatus == .denied {
                    divider
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notifications are turned off for Tixday in iOS Settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                        .font(.footnote.weight(.semibold))
                    }
                    .padding(16)
                }
            }
        }
        .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// The stored minutes after midnight as a date today, for the time picker.
    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderMinutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func requestPermission() async {
        await TicketNotifications.requestAuthorizationIfNeeded()
        await refreshNotificationStatus()
        // Home re-plans on the toggle too, but that can run before the user answers the prompt.
        await TicketNotifications.reschedule(events.map(\.snapshot))
    }

    // MARK: - Help

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            row("Help & FAQ", symbol: "questionmark.circle", external: true) { openURL(AppConfig.supportURL) }
            divider
            row("Contact Support", symbol: "envelope", external: true) { openURL(AppConfig.supportMailURL(version: versionText)) }
            divider
            row("Privacy Policy", symbol: "hand.raised", external: true) { openURL(AppConfig.privacyPolicyURL) }
            divider
            row("Terms of Use", symbol: "doc.text", external: true) { openURL(AppConfig.termsOfUseURL) }
        }
        .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Tixday \(version) (\(build))"
    }

    // MARK: - Pieces

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .textCase(.uppercase)
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            content()
        }
    }

    private func icon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 34, height: 34)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func row(_ title: LocalizedStringKey, symbol: String, external: Bool = false, isBusy: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon(symbol)
                Text(title).font(.body.weight(.medium))
                Spacer(minLength: 8)
                if isBusy {
                    ProgressView()
                } else {
                    Image(systemName: external ? "arrow.up.right" : "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .flipsForRightToLeftLayoutDirection(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 64)
    }
}
