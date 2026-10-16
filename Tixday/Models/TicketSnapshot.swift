import Foundation

/// A plain copy of an event, so ticket views and widget timelines don't hold SwiftData objects.
struct TicketSnapshot: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var kind: TicketKind
    var headline = ""
    var origin = ""
    var destination = ""
    var stubLeft = ""
    var stubRight = ""
    var createdAt = Date()
    var repeatsYearly = false
    var photoData: Data?
}

extension TicketSnapshot {
    /// One upcoming example per kind, then a used one; for previews, the widget gallery and the empty state.
    static func samples(now: Date = .now) -> [TicketSnapshot] {
        func inDays(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        }
        let created = Calendar.current.date(byAdding: .day, value: -50, to: now) ?? now
        // The birthday sample is always on 3 November, at the party's time.
        // Gregorian on purpose: with an Islamic or other calendar, "month 11" would be a different day.
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        let birthday = gregorian.nextDate(after: gregorian.startOfDay(for: now),
                                          matching: DateComponents(month: 11, day: 3, hour: 20),
                                          matchingPolicy: .nextTime) ?? inDays(24)
        return [
            TicketSnapshot(title: "Japan", date: inDays(83), kind: .flight, headline: "Tokyo", origin: "IST", destination: "HND", stubLeft: "GATE 03", stubRight: "14A", createdAt: created),
            TicketSnapshot(title: "Arctic Monkeys", date: inDays(18), kind: .concert, headline: "Arctic Monkeys", stubLeft: "SEC A · 12", stubRight: "21:00", createdAt: created),
            TicketSnapshot(title: "Finals", date: inDays(21), kind: .exam, headline: "Finals", stubLeft: "ROOM 4 · SEAT 17", stubRight: "09:30", createdAt: created),
            TicketSnapshot(title: "Our wedding", date: inDays(156), kind: .wedding, headline: "Elif & Can", stubLeft: "Bosphorus", stubRight: "19:00", createdAt: created),
            TicketSnapshot(title: String(localized: "My love's birthday", bundle: .app), date: birthday, kind: .birthday,
                           headline: String(localized: "My love", bundle: .app, comment: "Big name on the sample birthday ticket"), stubLeft: "No. 0024", stubRight: "20:00", createdAt: created, repeatsYearly: true),
            TicketSnapshot(title: "Christmas", date: inDays(77), kind: .holiday, headline: "Christmas", origin: "HOME", destination: "NORTH POLE", stubLeft: "CAR 25", stubRight: "08:15", createdAt: created, repeatsYearly: true),
            TicketSnapshot(title: "Coldplay", date: inDays(-12), kind: .concert, headline: "Coldplay", stubLeft: "FLOOR · 204", stubRight: "20:30", createdAt: created),
        ]
    }
}
