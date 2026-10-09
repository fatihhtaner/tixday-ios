import SwiftData
import SwiftUI

/// Home: a swipeable deck of upcoming tickets with a big live count, then every ticket as a list.
struct TicketListView: View {
    @Query(sort: \TicketEvent.date) private var events: [TicketEvent]
    @Namespace private var zoom
    @State private var isCreating = false
    @State private var focusedID: UUID?

    private var upcoming: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) >= 0 }
    }

    private var past: [TicketEvent] {
        events.filter { DayCount.days(until: $0.date) < 0 }.reversed()
    }

    private var focused: TicketEvent? {
        upcoming.first { $0.id == focusedID } ?? upcoming.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                    if events.isEmpty {
                        emptyState
                    } else {
                        if !upcoming.isEmpty {
                            deck
                                .padding(.top, 20)
                            countdownHeadline
                                .padding(.horizontal, 24)
                                .padding(.top, 22)
                        }
                        list
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                    }
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background { backdrop }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TicketEvent.self) { event in
                TicketDetailView(event: event)
                    .zoomTransition(id: event.id, in: zoom)
            }
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    // Fades the list out under the button so text doesn't clash with the glass.
                    LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas], startPoint: .top, endPoint: .bottom)
                        .frame(height: 130)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    newTicketButton
                }
            }
            .sheet(isPresented: $isCreating) {
                EventEditorView(event: nil)
            }
        }
        .tint(Theme.ink)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Tixday")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased())
                .font(Theme.eyebrow)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    /// The canvas takes on a wash of the ticket in focus.
    private var backdrop: some View {
        ZStack(alignment: .top) {
            Theme.canvas
            if let focused {
                RadialGradient(
                    colors: [focused.kind.style.background.opacity(0.8), focused.kind.style.background.opacity(0)],
                    center: .top,
                    startRadius: 20,
                    endRadius: 520
                )
                .frame(height: 640)
                .id(focused.kind)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: focused?.kind)
        .ignoresSafeArea()
    }

    // MARK: - Deck

    private var deck: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(upcoming) { event in
                    NavigationLink(value: event) {
                        TicketView(ticket: event.snapshot, size: .medium, notchColor: nil)
                            .frame(height: 196)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .ticketShadow()
                            .zoomSource(id: event.id, in: zoom)
                    }
                    .buttonStyle(PressableStyle())
                    .containerRelativeFrame(.horizontal) { width, _ in width - 48 }
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.9)
                            .rotation3DEffect(.degrees(phase.value * -14), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                    .id(event.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focusedID)
        .contentMargins(.horizontal, 24, for: .scrollContent)
        .scrollClipDisabled()
    }

    /// "83 days until Japan", following the ticket in focus.
    @ViewBuilder
    private var countdownHeadline: some View {
        if let focused {
            let days = DayCount.days(until: focused.date)
            VStack(alignment: .leading, spacing: 2) {
                Text(days, format: .number)
                    .font(.system(size: 76, weight: .black).width(.expanded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(days == 0 ? "Today: \(focused.title)" : days == 1 ? "day until \(focused.title)" : "days until \(focused.title)")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .animation(.snappy, value: focused.id)
        }
    }

    // MARK: - List

    private var list: some View {
        VStack(alignment: .leading, spacing: 28) {
            if !upcoming.isEmpty {
                listSection("All tickets", items: upcoming)
            }
            if !past.isEmpty {
                listSection("Used", items: past)
                    .opacity(0.6)
            }
        }
    }

    private func listSection(_ title: LocalizedStringKey, items: [TicketEvent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title).textCase(.uppercase)
                Text("\(items.count)").foregroundStyle(.tertiary)
            }
            .font(Theme.eyebrow)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)

            VStack(spacing: 8) {
                ForEach(items) { event in
                    NavigationLink(value: event) {
                        TicketRow(event: event)
                            .zoomSource(id: event.id, in: zoom)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: - Chrome

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
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A compact ticket in the list: coloured swatch, title and date, days left.
private struct TicketRow: View {
    let event: TicketEvent

    var body: some View {
        let style = event.kind.style
        let days = DayCount.days(until: event.date)
        HStack(spacing: 14) {
            Image(systemName: event.kind.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(style.ink)
                .frame(width: 48, height: 48)
                .background(style.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.ink.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(CountLabel.number(for: days))
                    .font(.system(size: 22, weight: .heavy).width(.expanded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text(CountLabel.text(for: days))
                    .font(.system(size: 9, weight: .semibold).width(.expanded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
