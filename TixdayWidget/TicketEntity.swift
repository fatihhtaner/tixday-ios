import AppIntents
import SwiftData
import WidgetKit

/// A ticket as the widget configuration sees it.
struct TicketEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Ticket"
    static let defaultQuery = TicketEntityQuery()

    let id: UUID
    let title: String
    let date: Date

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(date.formatted(date: .abbreviated, time: .omitted))"
        )
    }

    init(event: TicketEvent) {
        id = event.id
        title = event.title
        date = event.date
    }
}

struct TicketEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TicketEntity] {
        let context = ModelContext(SharedStore.makeContainer())
        let events = (try? context.fetch(FetchDescriptor<TicketEvent>())) ?? []
        return events.filter { identifiers.contains($0.id) }.map(TicketEntity.init)
    }

    /// Upcoming tickets first, soonest at the top; past ones after.
    func suggestedEntities() async throws -> [TicketEntity] {
        let context = ModelContext(SharedStore.makeContainer())
        let events = (try? context.fetch(FetchDescriptor<TicketEvent>(sortBy: [SortDescriptor(\.date)]))) ?? []
        let today = Calendar.current.startOfDay(for: .now)
        // Free users can only pick tickets within the free limit.
        let unlocked = TicketAccess.unlockedIDs(events.map { ($0.id, $0.date) }, isPro: TicketAccess.isPro)
        let usable = events.filter { unlocked.contains($0.id) }
        let upcoming = usable.filter { $0.date >= today }
        let past = usable.filter { $0.date < today }.reversed()
        return (upcoming + past).map(TicketEntity.init)
    }
}

/// Lets the user pin a widget to one ticket; left empty, it follows the next upcoming one.
struct SelectTicketIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose ticket"
    static let description = IntentDescription("Show one ticket, or leave empty to always show the next one.")

    @Parameter(title: "Ticket")
    var ticket: TicketEntity?
}
