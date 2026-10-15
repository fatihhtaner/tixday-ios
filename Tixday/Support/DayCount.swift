import Foundation

/// Countdown maths. Days are calendar days where the user is: tomorrow is always 1.
enum DayCount {
    static func days(until date: Date, from now: Date = .now, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// How far along the wait is, from when the ticket was created (0) to the day itself (1).
    static func progress(createdAt: Date, target: Date, now: Date = .now) -> Double {
        let total = target.timeIntervalSince(createdAt)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(createdAt) / total, 0), 1)
    }

    /// For a ticket that repeats every year: the next time its date comes round, today included.
    /// Always counted from the original date, so 29 February lands on 28 February in other years
    /// and returns to the 29th in leap years.
    static func nextOccurrence(of date: Date, from now: Date = .now, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        guard calendar.startOfDay(for: date) < today else { return date }
        var years = max(calendar.dateComponents([.year], from: date, to: today).year ?? 0, 0)
        var next = calendar.date(byAdding: .year, value: years, to: date) ?? date
        while calendar.startOfDay(for: next) < today {
            years += 1
            next = calendar.date(byAdding: .year, value: years, to: date) ?? next.addingTimeInterval(365 * 86_400)
        }
        return next
    }

    /// The next midnight, when every countdown changes.
    static func nextMidnight(after now: Date = .now, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(86_400)
    }
}
