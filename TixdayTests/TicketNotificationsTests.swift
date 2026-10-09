import XCTest
@testable import Tixday

final class TicketNotificationsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return calendar
    }

    private func date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = calendar.timeZone
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter.date(from: string)!
    }

    func testAllFourRemindersForAFarDate() {
        let reminders = TicketNotifications.reminderDates(for: date("2026-12-25T00:00:00"), now: date("2026-10-09T12:00:00"), calendar: calendar)
        XCTAssertEqual(reminders.map(\.daysBefore), [30, 7, 1, 0])
        XCTAssertEqual(reminders.first?.fireDate, date("2026-11-25T09:00:00"))
        XCTAssertEqual(reminders.last?.fireDate, date("2026-12-25T09:00:00"))
    }

    func testSkipsRemindersAlreadyPassed() {
        // Ten days out: the month reminder is gone, the week, day and day-of ones remain.
        let reminders = TicketNotifications.reminderDates(for: date("2026-10-19T00:00:00"), now: date("2026-10-09T12:00:00"), calendar: calendar)
        XCTAssertEqual(reminders.map(\.daysBefore), [7, 1, 0])
    }

    func testSameDayAfterNineHasNothingLeft() {
        let reminders = TicketNotifications.reminderDates(for: date("2026-10-09T20:00:00"), now: date("2026-10-09T10:00:00"), calendar: calendar)
        XCTAssertTrue(reminders.isEmpty)
    }
}
