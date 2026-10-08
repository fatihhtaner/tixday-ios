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

    var snapshot: TicketSnapshot {
        TicketSnapshot(
            id: id,
            title: title,
            date: date,
            kind: kind,
            headline: headline,
            origin: origin,
            destination: destination,
            stubLeft: stubLeft,
            stubRight: stubRight,
            createdAt: createdAt
        )
    }
}
