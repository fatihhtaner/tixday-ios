import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct TicketEntry: TimelineEntry {
    let date: Date
    /// nil when there is nothing to show (no tickets, or the chosen one was deleted).
    let ticket: TicketSnapshot?
    /// The chosen ticket is beyond the free limit since Pro ended.
    var isLocked = false
}

/// Shows the chosen ticket, or the soonest upcoming one, and refreshes at every midnight.
struct TicketProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TicketEntry {
        TicketEntry(date: .now, ticket: TicketSnapshot.samples()[0])
    }

    func snapshot(for configuration: SelectTicketIntent, in context: Context) async -> TicketEntry {
        if context.isPreview {
            return TicketEntry(date: .now, ticket: TicketSnapshot.samples()[0])
        }
        let ticket = ticket(for: configuration, now: .now) ?? TicketSnapshot.samples()[0]
        return TicketEntry(date: .now, ticket: ticket)
    }

    func timeline(for configuration: SelectTicketIntent, in context: Context) async -> Timeline<TicketEntry> {
        // One entry per midnight for the next week, so the count stays right even without a reload.
        var entries: [TicketEntry] = []
        var day = Date.now
        for _ in 0..<7 {
            if isLocked(configuration, now: day) {
                entries.append(TicketEntry(date: day, ticket: nil, isLocked: true))
            } else {
                entries.append(TicketEntry(date: day, ticket: ticket(for: configuration, now: day)))
            }
            day = DayCount.nextMidnight(after: day)
        }
        return Timeline(entries: entries, policy: .after(day))
    }

    /// A widget pinned to a ticket that is now beyond the free limit.
    private func isLocked(_ configuration: SelectTicketIntent, now: Date) -> Bool {
        guard let chosenID = configuration.pinnedID, !TicketAccess.isPro else { return false }
        let context = ModelContext(SharedStore.makeContainer())
        let events = (try? context.fetch(FetchDescriptor<TicketEvent>())) ?? []
        let unlocked = TicketAccess.unlockedIDs(events.map { ($0.id, $0.date) }, isPro: false, now: now)
        return events.contains { $0.id == chosenID } && !unlocked.contains(chosenID)
    }

    private func ticket(for configuration: SelectTicketIntent, now: Date) -> TicketSnapshot? {
        let context = ModelContext(SharedStore.makeContainer())
        if let id = configuration.pinnedID {
            var descriptor = FetchDescriptor<TicketEvent>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            // A deleted ticket falls back to the next upcoming one.
            if let pinned = (try? context.fetch(descriptor))?.first {
                return pinned.snapshot
            }
        }
        let today = Calendar.current.startOfDay(for: now)
        var descriptor = FetchDescriptor<TicketEvent>(
            predicate: #Predicate { $0.date >= today },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.snapshot
    }
}

struct NextTicketWidget: Widget {
    var body: some WidgetConfiguration {
        // Kind kept from the first version so widgets users already placed keep working.
        AppIntentConfiguration(kind: "NextTicket", intent: SelectTicketIntent.self, provider: TicketProvider()) { entry in
            NextTicketWidgetView(entry: entry)
                .environment(\.locale, AppLanguage.locale)
                .environment(\.layoutDirection, AppLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
        }
        .configurationDisplayName("Ticket")
        .description("Counts down to a date. Edit the widget to pick a ticket.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

struct NextTicketWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TicketEntry

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            Group {
                if AppGroup.defaults.bool(forKey: AppGroup.proUnlockedKey) {
                    LockScreenTicketView(ticket: entry.ticket, now: entry.date)
                } else {
                    LockScreenProPrompt()
                }
            }
            .containerBackground(for: .widget) { Color.clear }
        default:
            homeScreen
        }
    }

    @ViewBuilder
    private var homeScreen: some View {
        if entry.isLocked {
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                Text("Unlock with Tixday Pro")
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.secondary)
            .padding()
            .containerBackground(for: .widget) { Color(.systemBackground) }
        } else if let ticket = entry.ticket {
            TicketView(ticket: ticket, size: family == .systemMedium ? .medium : .small, now: entry.date)
                .containerBackground(for: .widget) { ticket.kind.style.background }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "ticket")
                    .font(.title2)
                Text("Add a ticket in Tixday")
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.secondary)
            .padding()
            .containerBackground(for: .widget) { Color(.systemBackground) }
        }
    }
}

/// Lock Screen versions: tinted by the system, so they rely on shape and type rather than ticket colours.
struct LockScreenTicketView: View {
    @Environment(\.widgetFamily) private var family
    var ticket: TicketSnapshot?
    var now: Date

    var body: some View {
        if let ticket {
            let days = DayCount.days(until: ticket.date, from: now)
            switch family {
            case .accessoryCircular:
                Gauge(value: DayCount.progress(createdAt: ticket.createdAt, target: ticket.date, now: now)) {
                    Image(systemName: ticket.kind.symbol)
                } currentValueLabel: {
                    VStack(spacing: -2) {
                        Text(CountLabel.number(for: days))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6)
                        Image(systemName: ticket.kind.symbol)
                            .font(.system(size: 9, weight: .semibold))
                            .widgetAccentable()
                    }
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryInline:
                Label {
                    Text(verbatim: "\(CountLabel.number(for: days)) \(CountLabel.text(for: days).lowercased(with: AppLanguage.locale)) · \(ticket.title)")
                } icon: {
                    Image(systemName: ticket.kind.symbol)
                }
            default:
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Label(ticket.kind.ticketLabel, systemImage: ticket.kind.symbol)
                            .font(.system(size: 10, weight: .bold))
                            .widgetAccentable()
                            .lineLimit(1)
                        Text(ticket.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(ticket.date.stubText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: -2) {
                        Text(CountLabel.number(for: days))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(CountLabel.text(for: days))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            switch family {
            case .accessoryInline:
                Label("Add a ticket in Tixday", systemImage: "ticket")
            default:
                Image(systemName: "ticket")
                    .font(.title2)
            }
        }
    }
}

/// Lock Screen sizes are part of Pro.
private struct LockScreenProPrompt: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Tixday Pro", systemImage: "lock.fill")
        case .accessoryCircular:
            Image(systemName: "lock.fill").font(.title3)
        default:
            Label("Unlock with Tixday Pro", systemImage: "lock.fill")
                .font(.headline)
        }
    }
}

#Preview(as: .accessoryRectangular) {
    NextTicketWidget()
} timeline: {
    for ticket in TicketSnapshot.samples() {
        TicketEntry(date: .now, ticket: ticket)
    }
}

#Preview(as: .systemSmall) {
    NextTicketWidget()
} timeline: {
    for ticket in TicketSnapshot.samples() {
        TicketEntry(date: .now, ticket: ticket)
    }
}

#Preview(as: .systemMedium) {
    NextTicketWidget()
} timeline: {
    for ticket in TicketSnapshot.samples() {
        TicketEntry(date: .now, ticket: ticket)
    }
}
