import SwiftData
import SwiftUI
import WidgetKit

/// Home: the next ticket as a hero with a live clock, then the rest stacked like passes in a wallet.
struct TicketListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TicketEvent.date) private var events: [TicketEvent]
    @Namespace private var zoom
    @State private var isCreating = false
    @State private var path: [TicketEvent] = []
    /// The stacked card the user tapped open; the last card of a stack is always open.
    @State private var openID: UUID?

    private var upcoming: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) >= 0 }
    }

    private var past: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) < 0 }.reversed()
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
                                .contextMenu { deleteButton(next) }
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
                            .saturation(0)
                            .opacity(0.55)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .pinnedTopBar { header.padding(.horizontal, 20).padding(.bottom, 10) }
            .background { PosterBackdrop(kind: upcoming.first?.kind, photo: TicketPhoto.image(upcoming.first?.photoData)) }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TicketEvent.self) { event in
                TicketDetailView(event: event)
                    .zoomTransition(id: event.id, in: zoom)
            }
            // Reserves room at the bottom so the last ticket can scroll clear of the button.
            .safeAreaInset(edge: .bottom) { newTicketButton }
            .sheet(isPresented: $isCreating) {
                EventEditorView(event: nil)
            }
        }
        // Like the editor and details, home sits in the next ticket's poster atmosphere.
        .environment(\.colorScheme, .dark)
        .tint(.white)
        // Re-plans reminders on launch and whenever a ticket is added, edited or deleted.
        .task(id: reminderSignature) {
            await TicketNotifications.reschedule(events.map(\.snapshot))
        }
    }

    private var reminderSignature: [String] {
        events.map { "\($0.id)|\($0.title)|\($0.date.timeIntervalSinceReferenceDate)" }
    }

    /// Today's date and how many tickets are waiting, instead of the app's name.
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased(with: .current))
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
            Text(upcoming.isEmpty ? String(localized: "Nothing planned yet") : String(localized: "\(upcoming.count) tickets ahead"))
                .font(Theme.display(24))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
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
            ForEach(items) { event in
                let isOpen = event.id == openID || event.id == items.last?.id
                Button {
                    if isOpen {
                        path.append(event)
                    } else {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { openID = event.id }
                    }
                } label: {
                    WalletCard(ticket: event.snapshot, isOpen: isOpen)
                        .zoomSource(id: event.id, in: zoom)
                }
                .buttonStyle(PressableStyle())
                .contextMenu { deleteButton(event) }
            }
        }
    }

    private func deleteButton(_ event: TicketEvent) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            context.delete(event)
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private var newTicketButton: some View {
        Button {
            isCreating = true
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
