import Foundation
import SwiftData

/// A date the user is counting down to. Every field has a default so the model stays CloudKit-compatible.
@Model
final class TicketEvent {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var kindRaw: String = TicketKind.flight.rawValue
    /// The big line on the ticket: artist, couple, whose birthday.
    var headline: String = ""
    /// Route codes for travel tickets, e.g. "IST" → "HND".
    var origin: String = ""
    var destination: String = ""
    /// Small print on the stub, e.g. "GATE 03" and "14A".
    var stubLeft: String = ""
    var stubRight: String = ""
    var createdAt: Date = Date()
    /// The user's own photo for the ticket body (a downscaled JPEG), replacing the kind's poster.
    @Attribute(.externalStorage) var photoData: Data?
    /// Birthdays, anniversaries and holidays: once the day has passed the ticket counts down to the
    /// same date next year. `date` keeps the original; `upcomingDate` is the one to count to.
    var repeatsYearly: Bool = false

    init(
        title: String,
        date: Date,
        kind: TicketKind,
        headline: String = "",
        origin: String = "",
        destination: String = "",
        stubLeft: String = "",
        stubRight: String = ""
    ) {
        self.title = title
        self.date = date
        self.kindRaw = kind.rawValue
        self.headline = headline
        self.origin = origin
        self.destination = destination
        self.stubLeft = stubLeft
        self.stubRight = stubRight
    }

    var kind: TicketKind {
        get { TicketKind(rawValue: kindRaw) ?? .flight }
        set { kindRaw = newValue.rawValue }
    }

    /// The date to count down to: `date`, or for a yearly ticket its next anniversary.
    func upcomingDate(from now: Date = .now) -> Date {
        repeatsYearly ? DayCount.nextOccurrence(of: date, from: now) : date
    }

    var snapshot: TicketSnapshot { snapshot(at: .now) }

    /// The ticket as it looks on a given day; widgets build their timelines days ahead.
    func snapshot(at now: Date) -> TicketSnapshot {
        let target = upcomingDate(from: now)
        // A yearly ticket's wait starts again at the last anniversary.
        let lastTime = Calendar.current.date(byAdding: .year, value: -1, to: target) ?? createdAt
        return TicketSnapshot(
            id: id,
            title: title,
            date: target,
            kind: kind,
            headline: headline,
            origin: origin,
            destination: destination,
            stubLeft: stubLeft,
            stubRight: stubRight,
            createdAt: repeatsYearly && target != date ? max(createdAt, lastTime) : createdAt,
            repeatsYearly: repeatsYearly,
            // Photos are a Pro feature: kept in the store, shown only while Pro is active.
            photoData: TicketAccess.isPro ? photoData : nil
        )
    }
}
