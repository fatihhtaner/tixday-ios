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
}
