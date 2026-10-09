import XCTest
@testable import Tixday

final class TicketAccessTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_791_500_000)

    private func ticket(inDays days: Int) -> (id: UUID, date: Date) {
        (UUID(), Calendar.current.date(byAdding: .day, value: days, to: now)!)
    }

    func testFreeUnlocksTheThreeSoonestUpcoming() {
        let tickets = [ticket(inDays: 40), ticket(inDays: 5), ticket(inDays: 90), ticket(inDays: 12), ticket(inDays: 1)]
        let unlocked = TicketAccess.unlockedIDs(tickets, isPro: false, now: now)
        XCTAssertEqual(unlocked, Set([tickets[4].id, tickets[1].id, tickets[3].id]))
    }

    func testPastTicketsStayUnlockedAndDontUseTheLimit() {
        let tickets = [ticket(inDays: -10), ticket(inDays: -2), ticket(inDays: 3), ticket(inDays: 4), ticket(inDays: 5), ticket(inDays: 6)]
        let unlocked = TicketAccess.unlockedIDs(tickets, isPro: false, now: now)
        XCTAssertEqual(unlocked.count, 5)
        XCTAssertFalse(unlocked.contains(tickets[5].id))
        XCTAssertEqual(TicketAccess.upcomingCount(tickets.map(\.date), now: now), 4)
    }

    func testProUnlocksEverything() {
        let tickets = (1...8).map { ticket(inDays: $0) }
        XCTAssertEqual(TicketAccess.unlockedIDs(tickets, isPro: true, now: now).count, 8)
    }
}
