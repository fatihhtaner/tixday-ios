import SwiftData
import SwiftUI
import WidgetKit

/// Home: every ticket, soonest first, like passes in a wallet; used ones at the bottom.
struct TicketListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TicketEvent.date) private var events: [TicketEvent]
    @Namespace private var zoom
    @State private var isCreating = false

    private var upcoming: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) >= 0 }
    }

    private var past: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) < 0 }.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if events.isEmpty {
                        emptyState
                    } else {
                        if !upcoming.isEmpty {
                            section("Upcoming", items: upcoming)
                        }
                        if !past.isEmpty {
                            section("Used", items: past)
                                .saturation(0)
                                .opacity(0.55)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
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
        .tint(Theme.ink)
        // Re-plans reminders on launch and whenever a ticket is added, edited or deleted.
        .task(id: reminderSignature) {
            await TicketNotifications.reschedule(events.map(\.snapshot))
        }
    }

    private var reminderSignature: [String] {
        events.map { "\($0.id)|\($0.title)|\($0.date.timeIntervalSinceReferenceDate)" }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Tixday")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased(with: .current))
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func section(_ title: LocalizedStringKey, items: [TicketEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(title).textCase(.uppercase)
                Text("\(items.count)").foregroundStyle(.tertiary)
            }
            .font(Theme.eyebrow)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)

            ForEach(items) { event in
                NavigationLink(value: event) {
                    TicketView(ticket: event.snapshot, size: .medium, notchColor: nil)
                        .frame(height: 172)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .ticketShadow()
                        .zoomSource(id: event.id, in: zoom)
                }
                .buttonStyle(PressableStyle())
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        context.delete(event)
                        try? context.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
    }

    private var newTicketButton: some View {
        Button {
            isCreating = true
        } label: {
            Label("New ticket", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
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
                .foregroundStyle(Theme.ink)
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
