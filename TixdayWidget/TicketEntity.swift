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

    /// The "Next ticket" choice: not a real ticket, the widget follows the soonest upcoming one.
    static let nextUpcomingID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    static let nextUpcoming = TicketEntity(id: nextUpcomingID, title: "", date: .distantFuture)

    var displayRepresentation: DisplayRepresentation {
        if id == Self.nextUpcomingID {
            return DisplayRepresentation(title: "Next ticket", subtitle: "Always the soonest one")
        }
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: AppLanguage.locale)))"
        )
    }

    private init(id: UUID, title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
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
        let tickets = events.filter { identifiers.contains($0.id) }.map(TicketEntity.init)
        return identifiers.contains(TicketEntity.nextUpcomingID) ? [.nextUpcoming] + tickets : tickets
    }

    /// New widgets start on "Next ticket" instead of an empty choice.
    func defaultResult() async -> TicketEntity? {
        .nextUpcoming
    }

    /// "Next ticket", then upcoming tickets, soonest at the top; past ones after.
    func suggestedEntities() async throws -> [TicketEntity] {
        let context = ModelContext(SharedStore.makeContainer())
        let events = (try? context.fetch(FetchDescriptor<TicketEvent>(sortBy: [SortDescriptor(\.date)]))) ?? []
        let today = Calendar.current.startOfDay(for: .now)
        // Free users can only pick tickets within the free limit.
        let unlocked = TicketAccess.unlockedIDs(events.map { ($0.id, $0.date) }, isPro: TicketAccess.isPro)
        let usable = events.filter { unlocked.contains($0.id) }
        let upcoming = usable.filter { $0.date >= today }
        let past = usable.filter { $0.date < today }.reversed()
        return [.nextUpcoming] + (upcoming + past).map(TicketEntity.init)
    }
}

/// Lets the user pin a widget to one ticket; left empty, it follows the next upcoming one.
struct SelectTicketIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose ticket"
    static let description = IntentDescription("Show one ticket, or leave empty to always show the next one.")

    @Parameter(title: "Ticket")
    var ticket: TicketEntity?

    /// The ticket the widget is pinned to; nil follows the next upcoming one.
    var pinnedID: UUID? {
        guard let id = ticket?.id, id != TicketEntity.nextUpcomingID else { return nil }
        return id
    }
}
