import SwiftData
import SwiftUI
import WidgetKit

struct TicketEntry: TimelineEntry {
    let date: Date
    /// nil when the user has no upcoming tickets.
    let ticket: TicketSnapshot?
}

/// Shows the soonest upcoming ticket and refreshes at every midnight.
struct NextTicketProvider: TimelineProvider {
    func placeholder(in context: Context) -> TicketEntry {
        TicketEntry(date: .now, ticket: TicketSnapshot.samples()[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (TicketEntry) -> Void) {
        let ticket = context.isPreview ? TicketSnapshot.samples()[0] : nextTicket(from: .now)
        completion(TicketEntry(date: .now, ticket: ticket ?? TicketSnapshot.samples()[0]))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TicketEntry>) -> Void) {
        // One entry per midnight for the next week, so the count stays right even without a reload.
        var entries: [TicketEntry] = []
        var day = Date.now
        for _ in 0..<7 {
            entries.append(TicketEntry(date: day, ticket: nextTicket(from: day)))
            day = DayCount.nextMidnight(after: day)
        }
        completion(Timeline(entries: entries, policy: .after(day)))
    }

    private func nextTicket(from now: Date) -> TicketSnapshot? {
        let context = ModelContext(SharedStore.makeContainer())
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
        StaticConfiguration(kind: "NextTicket", provider: NextTicketProvider()) { entry in
            NextTicketWidgetView(entry: entry)
        }
        .configurationDisplayName("Next ticket")
        .description("Counts down to your soonest date.")
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
