import StoreKit
import SwiftData
import SwiftUI
import WidgetKit

/// Home: the next ticket as a hero with a live clock, then the rest stacked like passes in a wallet.
struct TicketListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TicketEvent.date) private var events: [TicketEvent]
    @Environment(ProStore.self) private var pro
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    /// How many tickets there were when the editor opened, to tell whether one was added.
    @State private var countBeforeCreating = 0
    @State private var paywallReason: ProFeature?
    @Namespace private var zoom
    @State private var isCreating = false
    /// The ticket being edited or about to be deleted from a card's menu.
    @State private var editing: TicketEvent?
    @State private var deleting: TicketEvent?
    @State private var isShowingSettings = false
    @State private var isOnboarding = false
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false
    @AppStorage(ReminderSettings.enabledKey) private var remindersEnabled = true
    @AppStorage(ReminderSettings.timeKey) private var reminderMinutes = ReminderSettings.defaultMinutes
    @State private var path: [TicketEvent] = []
    /// The stacked card the user tapped open; the last card of a stack is always open.
    @State private var openID: UUID?
    /// Today, so the screen redraws when the day changes while the app stays open in the background.
    @State private var today = Calendar.current.startOfDay(for: .now)
    private let router = LinkRouter.shared

    /// Every ticket with the date it counts to (a yearly ticket's next anniversary), soonest first.
    private var dated: [(event: TicketEvent, date: Date)] {
        events.map { ($0, $0.upcomingDate(from: today)) }.sorted { $0.date < $1.date }
    }

    private var upcoming: [TicketEvent] {
        dated.filter { DayCount.days(until: $0.date, from: today) >= 0 }.map(\.event)
    }

    /// Tickets a free user can use; the rest show locked (see `TicketAccess`).
    private var unlockedIDs: Set<UUID> {
        TicketAccess.unlockedIDs(for: events, isPro: pro.isPro, now: today)
    }

    private var past: [TicketEvent] {
        dated.filter { DayCount.days(until: $0.date, from: today) < 0 }.map(\.event).reversed()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if events.isEmpty {
                        emptyState
                    } else {
                        if let next = upcoming.first {
                            titled("Next up") {
                                Button {
                                    path.append(next)
                                } label: {
                                    HeroTicket(ticket: next.snapshot)
                                        .zoomSource(id: next.id, in: zoom)
                                }
                                .buttonStyle(PressableStyle())
                                .contextMenu { cardMenu(next, isLocked: false) }
                            }
                        }
                        if upcoming.count > 1 {
                            titled("Wallet", count: upcoming.count - 1) {
                                stack(Array(upcoming.dropFirst()))
                            }
                        }
                        if !past.isEmpty {
                            titled("Used", count: past.count) {
                                stack(past)
                            }
                            .opacity(0.8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                // Counts and dates are read when drawn; a new day draws everything again.
                .id(today)
            }
            .scrollIndicators(.hidden)
            .pinnedTopBar { header.padding(.horizontal, 20).padding(.bottom, 10).id(today) }
            .background { PosterBackdrop(kind: upcoming.first?.kind, photo: TicketPhoto.image(upcoming.first?.snapshot.photoData)) }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TicketEvent.self) { event in
                TicketDetailView(event: event)
                    .zoomTransition(id: event.id, in: zoom)
            }
            // Reserves room at the bottom so the last ticket can scroll clear of the button.
            .safeAreaInset(edge: .bottom) { newTicketButton }
            .sheet(isPresented: $isCreating, onDismiss: askForReviewAfterCreating) {
                EventEditorView(event: nil).appLanguage()
            }
            .onChange(of: isCreating) { _, isOpen in
                if isOpen { countBeforeCreating = events.count }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason).appLanguage()
            }
            .sheet(item: $editing) { event in
                EventEditorView(event: event).appLanguage()
            }
            .confirmationDialog(
                "Delete this ticket?",
                isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                titleVisibility: .visible,
                presenting: deleting
            ) { event in
                Button("Delete", role: .destructive) { delete(event) }
            } message: { event in
                Text(event.title)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView().appLanguage()
            }
            #if DEBUG
            .fullScreenCover(isPresented: $isShowingWidgetShowcase) {
                // "my-widgets" shows the tickets in the store (the tutorial's new trip), "widgets" the samples.
                WidgetShowcaseView(tickets: DemoMode.screen == "my-widgets" ? upcoming.map(\.snapshot) : nil)
            }
            #endif
            .fullScreenCover(isPresented: $isOnboarding) {
                OnboardingView { createTicket in
                    didFinishOnboarding = true
                    isOnboarding = false
                    if createTicket { isCreating = true }
                }
                .appLanguage()
            }
            .onAppear {
                showOnboardingIfNeeded()
                openPendingLink()
                askForReviewOnTicketDay()
            }
            .onChange(of: router.pending) { _, _ in openPendingLink() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshToday() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                refreshToday()
            }
        }
        // Like the editor and details, home sits in the next ticket's poster atmosphere.
        .environment(\.colorScheme, .dark)
        .tint(.white)
        // Re-plans reminders on launch and whenever a ticket is added, edited or deleted.
        .task(id: reminderSignature) {
            await TicketNotifications.reschedule(events.map(\.snapshot))
        }
        // Tickets also change through iCloud from another device; keep the widgets in step.
        .onChange(of: reminderSignature) { _, _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// A second ticket means Tixday is becoming a habit: a good moment to ask for a rating.
    private func askForReviewAfterCreating() {
        guard events.count >= 2, events.count > countBeforeCreating else { return }
        askForReview()
    }

    /// The day a ticket was counting down to has arrived.
    private func askForReviewOnTicketDay() {
        guard upcoming.contains(where: { DayCount.days(until: $0.upcomingDate(from: today), from: today) == 0 }) else { return }
        askForReview()
    }

    private func askForReview() {
        guard ReviewPrompt.isDue(), !isOnboarding else { return }
        ReviewPrompt.markAsked()
        Task {
            // Let sheets and transitions settle first.
            try? await Task.sleep(for: .seconds(1.2))
            requestReview()
        }
    }

    private func refreshToday() {
        let start = Calendar.current.startOfDay(for: .now)
        if start != today {
            today = start
            askForReviewOnTicketDay()
        }
    }

    /// Opens what a widget or reminder pointed at: the ticket's details, or the paywall when it's locked.
    private func openPendingLink() {
        guard let link = router.pending, !isOnboarding else { return }
        router.pending = nil
        isCreating = false
        editing = nil
        isShowingSettings = false
        switch link {
        case .pro:
            if !pro.isPro { paywallReason = .lockScreen }
        case .ticket(let id):
            guard let event = events.first(where: { $0.id == id }) else { return }
            if unlockedIDs.contains(id) {
                paywallReason = nil
                path = [event]
            } else {
                path = []
                paywallReason = .unlimitedTickets
            }
        }
    }

    /// Once, on a first launch with no tickets; people who already have tickets skip it.
    private func showOnboardingIfNeeded() {
        #if DEBUG
        if CommandLine.arguments.contains("-onboarding") {
            isOnboarding = true
            return
        }
        if openScreenshotScreen() { return }
        #endif
        guard !didFinishOnboarding else { return }
        if events.isEmpty {
            isOnboarding = true
        } else {
            didFinishOnboarding = true
        }
    }

    #if DEBUG
    @State private var isShowingWidgetShowcase = false

    /// `-screenshotScreen <name>` opens one screen for the App Store screenshots (with `-sampleData`):
    /// `detail-birthday`, `detail-used`, `editor` or `widgets`.
    private func openScreenshotScreen() -> Bool {
        guard let screen = DemoMode.screen else { return false }
        switch screen {
        case "detail-birthday":
            if let event = events.first(where: { $0.kind == .birthday }) { path = [event] }
        case "detail-used":
            if let event = past.first { path = [event] }
        case "editor":
            editing = events.first { $0.kind == .flight }
        case "widgets", "my-widgets":
            isShowingWidgetShowcase = true
        case "create-demo":
            // Tutorial video: a beat on the empty home, then "New ticket"; the editor plays the rest.
            Task {
                try? await Task.sleep(for: .seconds(2.0))
                isCreating = true
            }
        default:
            return false
        }
        return true
    }
    #endif

    private var reminderSignature: [String] {
        // Includes today, so a yearly ticket that just rolled over gets next year's reminders.
        events.map { "\($0.id)|\($0.title)|\($0.date.timeIntervalSinceReferenceDate)|\($0.repeatsYearly)" }
            + ["today|\(today.timeIntervalSinceReferenceDate)"]
            + ["reminders|\(remindersEnabled)|\(reminderMinutes)"]
    }

    /// Today's date and how many tickets are waiting, instead of the app's name.
    private var header: some View {
        HStack(alignment: .top) {
            headerTitles
            Spacer(minLength: 8)
            if !pro.isPro {
                Button {
                    paywallReason = .unlimitedTickets
                } label: {
                    Label("Pro", systemImage: "sparkles")
                        .font(.footnote.weight(.bold))
                        // A small chrome badge: grows with the text size, but not past the header.
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .contentShape(Capsule())
                        .glassBackground(in: Capsule(), interactive: true)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
            CircleIconButton(title: "Settings", systemImage: "gearshape", size: 34) {
                isShowingSettings = true
            }
        }
        .padding(.top, 4)
    }

    private var headerTitles: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(AppLanguage.locale)).uppercased(with: AppLanguage.locale))
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
            Text(upcoming.isEmpty ? String(localized: "Nothing planned yet", bundle: .app) : String(localized: "\(upcoming.count) tickets ahead", bundle: .app))
                .font(Theme.display(24))
                .foregroundStyle(Color.primary)
                // Two lines rather than cut off when space is tight (large text, long languages).
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func titled<Content: View>(_ title: LocalizedStringKey, count: Int? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(title).textCase(.uppercase)
                if let count { Text("\(count)").foregroundStyle(.tertiary) }
            }
            .font(Theme.eyebrow)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            content()
        }
    }

    /// Cards overlap so only their coloured headers show. Tapping a closed card opens it in place;
    /// tapping an open one shows its details.
    private func stack(_ items: [TicketEvent]) -> some View {
        VStack(spacing: -WalletCard.overlap) {
            let unlocked = unlockedIDs
            ForEach(items) { event in
                let isLocked = !unlocked.contains(event.id)
                let isOpen = !isLocked && (event.id == openID || event.id == items.last?.id)
                Button {
                    if isLocked {
                        paywallReason = .unlimitedTickets
                    } else if isOpen {
                        path.append(event)
                    } else {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { openID = event.id }
                    }
                } label: {
                    WalletCard(ticket: event.snapshot, isOpen: isOpen, isLocked: isLocked)
                        .zoomSource(id: event.id, in: zoom)
                }
                .buttonStyle(PressableStyle())
                .contextMenu { cardMenu(event, isLocked: isLocked) }
            }
        }
    }

    /// Long-press menu on a ticket. Locked tickets can only be deleted until Pro is back.
    @ViewBuilder
    private func cardMenu(_ event: TicketEvent, isLocked: Bool) -> some View {
        if !isLocked {
            Button("Edit", systemImage: "pencil") { editing = event }
            // Menus are built when they open, so only the pressed ticket is drawn.
            let card = TicketShareCard(ticket: event.snapshot)
            ShareLink(item: card, preview: SharePreview(event.title, image: Image(uiImage: card.image()))) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        Button("Delete", systemImage: "trash", role: .destructive) { deleting = event }
    }

    private func delete(_ event: TicketEvent) {
        if openID == event.id { openID = nil }
        withAnimation(.snappy) {
            context.delete(event)
            try? context.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var newTicketButton: some View {
        Button {
            if pro.canAddTicket(upcomingCount: upcoming.count) {
                isCreating = true
            } else {
                paywallReason = .unlimitedTickets
            }
        } label: {
            Label("New ticket", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                .contentShape(Capsule())
                .glassBackground(in: Capsule(), interactive: true)
        }
        .buttonStyle(PressableStyle())
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(Array([1, 3, 0].enumerated()), id: \.offset) { index, sample in
                    TicketView(ticket: TicketSnapshot.samples()[sample], size: .small, notchColor: nil)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .ticketShadow()
                        .rotationEffect(.degrees([-10, 9, 0][index]))
                        .offset(x: [-62, 62, 0][index], y: [12, 16, 0][index])
                }
            }
            .frame(height: 210)
            .padding(.top, 48)
            .accessibilityHidden(true)

            Text("Every date is a ticket")
                .font(Theme.display(22))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
            Text("Add the day you're waiting for and watch it count down on your Home Screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
    }
}
