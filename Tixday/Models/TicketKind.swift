import Foundation

/// Each event type has its own ticket design.
enum TicketKind: String, CaseIterable, Identifiable, Codable {
    case flight
    case concert
    case exam
    case wedding
    case birthday
    case holiday

    var id: String { rawValue }

    var name: String {
        switch self {
        case .flight: String(localized: "Trip")
        case .concert: String(localized: "Concert")
        case .exam: String(localized: "Exam")
        case .wedding: String(localized: "Wedding")
        case .birthday: String(localized: "Birthday")
        case .holiday: String(localized: "Holiday")
        }
    }

    var symbol: String {
        switch self {
        case .flight: "airplane.departure"
        case .concert: "music.mic"
        case .exam: "pencil.and.list.clipboard"
        case .wedding: "heart"
        case .birthday: "birthday.cake"
        case .holiday: "tram"
        }
    }

    /// Kinds that show a "from → to" route on the ticket.
    var showsRoute: Bool { self == .flight || self == .holiday }

    var headlinePrompt: String {
        switch self {
        case .flight: String(localized: "Trip name")
        case .concert: String(localized: "Artist")
        case .exam: String(localized: "Exam name")
        case .wedding: String(localized: "Couple")
        case .birthday: String(localized: "Whose birthday?")
        case .holiday: String(localized: "Holiday name")
        }
    }

    var stubLeftPrompt: String {
        switch self {
        case .flight: "GATE 03"
        case .concert: "SEC A · 12"
        case .exam: "ROOM 4 · SEAT 17"
        case .wedding: String(localized: "Venue")
        case .birthday: "No. 0024"
        case .holiday: "CAR 25"
        }
    }

    var stubRightPrompt: String {
        switch self {
        case .flight: "14A"
        case .concert: "21:00"
        case .exam: "09:30"
        case .wedding: "19:00"
        case .birthday: "20:00"
        case .holiday: "08:15"
        }
    }
}
