import SwiftData
import SwiftUI

/// Home: the next ticket as a hero, the rest as a wall of small tickets, used ones at the bottom.
struct TicketListView: View {
    @Query(sort: \TicketEvent.date) private var events: [TicketEvent]
    @State private var isCreating = false

    private var upcoming: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) >= 0 }
    }

    private var past: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) < 0 }.reversed()
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if events.isEmpty {
                        emptyState
                    } else {
                        if let next = upcoming.first {
                            section("Next up") {
                                NavigationLink(value: next) {
                                    TicketView(ticket: next.snapshot, size: .medium, notchColor: nil)
                                        .frame(height: 172)
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        .ticketShadow()
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        if upcoming.count > 1 {
                            section("Upcoming", count: upcoming.count - 1) {
                                grid(Array(upcoming.dropFirst()))
                            }
                        }
                        if !past.isEmpty {
                            section("Used tickets", count: past.count) {
                                grid(past)
                                    .saturation(0)
                                    .opacity(0.6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TicketEvent.self) { event in
                TicketDetailView(event: event)
            }
            .overlay(alignment: .bottom) {
                newTicketButton
            }
            .sheet(isPresented: $isCreating) {
                EventEditorView(event: nil)
            }
        }
        .tint(Theme.ink)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
            Text("Tixday")
                .font(Theme.display(38))
                .foregroundStyle(Theme.ink)
        }
        .padding(.top, 12)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, count: Int? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(title).textCase(.uppercase)
                if let count { Text("\(count)").foregroundStyle(.tertiary) }
            }
            .font(Theme.eyebrow)
            .foregroundStyle(.secondary)
            content()
        }
    }

    private func grid(_ items: [TicketEvent]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { event in
                NavigationLink(value: event) {
                    TicketView(ticket: event.snapshot, size: .small, notchColor: nil)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .ticketShadow()
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private var newTicketButton: some View {
        Button {
            isCreating = true
        } label: {
            Label("New ticket", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.canvas)
                .padding(.horizontal, 24)
                .padding(.vertical, 15)
                .background(Theme.ink, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        }
        .buttonStyle(PressableStyle())
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                TicketView(ticket: TicketSnapshot.samples()[1], size: .small, notchColor: nil)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .rotationEffect(.degrees(-10))
                    .offset(x: -60, y: 10)
                TicketView(ticket: TicketSnapshot.samples()[3], size: .small, notchColor: nil)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .rotationEffect(.degrees(9))
                    .offset(x: 60, y: 14)
                TicketView(ticket: TicketSnapshot.samples()[0], size: .small, notchColor: nil)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .ticketShadow()
            }
            .frame(height: 200)
            .padding(.top, 24)

            Text("Every date is a ticket")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Add the day you're waiting for and watch it count down on your Home Screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Slight shrink on touch, so tickets feel like physical cards.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
