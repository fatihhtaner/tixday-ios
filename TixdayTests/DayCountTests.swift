import XCTest
@testable import Tixday

final class DayCountTests: XCTestCase {
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

    func testTomorrowIsOneEvenLateAtNight() {
        let now = date("2026-10-09T23:50:00")
        let target = date("2026-10-10T00:10:00")
        XCTAssertEqual(DayCount.days(until: target, from: now, calendar: calendar), 1)
    }

    func testSameDayIsZero() {
        let now = date("2026-10-09T08:00:00")
        let target = date("2026-10-09T22:00:00")
        XCTAssertEqual(DayCount.days(until: target, from: now, calendar: calendar), 0)
    }

    func testPastDateIsNegative() {
        let now = date("2026-10-09T12:00:00")
        let target = date("2026-10-01T12:00:00")
        XCTAssertEqual(DayCount.days(until: target, from: now, calendar: calendar), -8)
    }

    func testProgressIsClamped() {
        let created = date("2026-10-01T00:00:00")
        let target = date("2026-10-11T00:00:00")
        XCTAssertEqual(DayCount.progress(createdAt: created, target: target, now: date("2026-10-06T00:00:00")), 0.5, accuracy: 0.001)
        XCTAssertEqual(DayCount.progress(createdAt: created, target: target, now: date("2026-09-01T00:00:00")), 0)
        XCTAssertEqual(DayCount.progress(createdAt: created, target: target, now: date("2026-12-01T00:00:00")), 1)
    }

    func testCountLabels() {
        XCTAssertEqual(CountLabel.number(for: -3), "3")
        XCTAssertEqual(CountLabel.text(for: 0), String(localized: "TODAY", bundle: .app))
        // The unit's plural variations leave the number out; it is drawn separately.
        XCTAssertFalse(CountLabel.text(for: 5).contains("5"))
        XCTAssertFalse(CountLabel.text(for: 1).contains("1"))
    }

    func testYearlyTicketCountsToNextAnniversary() {
        let now = date("2026-10-15T12:00:00")
        // Born 1990-03-02: next one is 2027-03-02.
        XCTAssertEqual(DayCount.nextOccurrence(of: date("1990-03-02T00:00:00"), from: now, calendar: calendar), date("2027-03-02T00:00:00"))
        // Later this year stays this year.
        XCTAssertEqual(DayCount.nextOccurrence(of: date("2020-12-25T00:00:00"), from: now, calendar: calendar), date("2026-12-25T00:00:00"))
        // The day itself counts as today, not next year.
        XCTAssertEqual(DayCount.nextOccurrence(of: date("2025-10-15T00:00:00"), from: now, calendar: calendar), date("2026-10-15T00:00:00"))
        // A future date is left alone.
        XCTAssertEqual(DayCount.nextOccurrence(of: date("2027-01-01T00:00:00"), from: now, calendar: calendar), date("2027-01-01T00:00:00"))
    }

    func testLeapDayAnniversary() {
        let leapDay = date("2024-02-29T00:00:00")
        XCTAssertEqual(DayCount.nextOccurrence(of: leapDay, from: date("2026-10-15T12:00:00"), calendar: calendar), date("2027-02-28T00:00:00"))
        XCTAssertEqual(DayCount.nextOccurrence(of: leapDay, from: date("2027-10-15T12:00:00"), calendar: calendar), date("2028-02-29T00:00:00"))
    }

    func testAccessibilityDescriptionReadsTheWholeTicket() {
        let now = Date.now
        let ticket = TicketSnapshot(title: "Arctic Monkeys", date: Calendar.current.date(byAdding: .day, value: 18, to: now)!, kind: .concert)
        let text = ticket.accessibilityDescription(now: now)
        XCTAssertTrue(text.contains("Arctic Monkeys"))
        XCTAssertTrue(text.contains("18"))
        XCTAssertTrue(text.contains(TicketKind.concert.name))
        let used = TicketSnapshot(title: "Coldplay", date: Calendar.current.date(byAdding: .day, value: -3, to: now)!, kind: .concert)
        XCTAssertTrue(used.accessibilityDescription(now: now).contains("3"))
    }
}
