import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct TicketEntry: TimelineEntry {
    let date: Date
    /// nil when there is nothing to show (no tickets, or the chosen one was deleted).
    let ticket: TicketSnapshot?
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
            entries.append(TicketEntry(date: day, ticket: ticket(for: configuration, now: day)))
            day = DayCount.nextMidnight(after: day)
        }
        return Timeline(entries: entries, policy: .after(day))
    }

    private func ticket(for configuration: SelectTicketIntent, now: Date) -> TicketSnapshot? {
        let context = ModelContext(SharedStore.makeContainer())
        if let chosen = configuration.ticket {
            let id = chosen.id
            var descriptor = FetchDescriptor<TicketEvent>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            return (try? context.fetch(descriptor))?.first?.snapshot
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
        }
        .configurationDisplayName("Ticket")
        .description("Counts down to a date. Edit the widget to pick a ticket.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct NextTicketWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TicketEntry

    var body: some View {
        if let ticket = entry.ticket {
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
