import Foundation

/// Links into the app from widgets and reminders: `tixday://ticket/<id>` opens a ticket,
/// `tixday://pro` the paywall.
enum DeepLink: Equatable {
    case ticket(UUID)
    case pro

    static let scheme = "tixday"

    var url: URL {
        switch self {
        case .ticket(let id): URL(string: "\(Self.scheme)://ticket/\(id.uuidString)")!
        case .pro: URL(string: "\(Self.scheme)://pro")!
        }
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "ticket":
            guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
            self = .ticket(id)
        case "pro":
            self = .pro
        default:
            return nil
        }
    }
}
