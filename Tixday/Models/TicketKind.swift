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
        case .flight: String(localized: "Trip", bundle: .app)
        case .concert: String(localized: "Concert", bundle: .app)
        case .exam: String(localized: "Exam", bundle: .app)
        case .wedding: String(localized: "Wedding", bundle: .app)
        case .birthday: String(localized: "Birthday", bundle: .app)
        case .holiday: String(localized: "Holiday", bundle: .app)
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
        case .flight: String(localized: "Trip name", bundle: .app)
        case .concert: String(localized: "Artist", bundle: .app)
        case .exam: String(localized: "Exam name", bundle: .app)
        case .wedding: String(localized: "Couple", bundle: .app)
        case .birthday: String(localized: "Whose birthday?", bundle: .app)
        case .holiday: String(localized: "Holiday name", bundle: .app)
        }
    }

    var stubLeftPrompt: String {
        switch self {
        case .flight: "GATE 03"
        case .concert: "SEC A · 12"
        case .exam: "ROOM 4 · SEAT 17"
        case .wedding: String(localized: "Venue", bundle: .app)
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
