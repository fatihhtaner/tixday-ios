import Foundation

/// What a free user can use: the three soonest upcoming tickets. Tickets beyond that stay saved and
/// visible but locked, so a cancelled trial or subscription never deletes anything.
enum TicketAccess {
    static let freeLimit = 3

    /// Whether Pro is active, as last mirrored into the App Group by the app.
    static var isPro: Bool { AppGroup.defaults.bool(forKey: AppGroup.proUnlockedKey) }

    /// The tickets a user may open, edit and put on widgets. Past tickets are never locked.
    static func unlockedIDs(_ tickets: [(id: UUID, date: Date)], isPro: Bool, now: Date = .now) -> Set<UUID> {
        if isPro { return Set(tickets.map(\.id)) }
        let today = Calendar.current.startOfDay(for: now)
        let past = tickets.filter { $0.date < today }.map(\.id)
        let soonest = tickets.filter { $0.date >= today }.sorted { $0.date < $1.date }.prefix(freeLimit).map(\.id)
        return Set(past + soonest)
    }

    /// Upcoming tickets count toward the free limit; past ones don't.
    static func upcomingCount(_ dates: [Date], now: Date = .now) -> Int {
        let today = Calendar.current.startOfDay(for: now)
        return dates.filter { $0 >= today }.count
    }
}
