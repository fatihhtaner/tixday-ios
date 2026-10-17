import SwiftUI

/// Colours and type for one ticket design.
struct TicketStyle {
    /// Body colour when there is no poster or photo.
    var background: Color
    var ink: Color
    var muted: Color
    var accent: Color
    var perforation: Color
    var design: Font.Design
    var numberWidth: Font.Width = .standard
    /// The solid tear-off stub that carries the count.
    var stubFill: Color
    var stubInk: Color
    var stubMuted: Color
    /// How dark the poster's scrim gets behind white type; bright posters need more.
    var scrim: Double = 1

    func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: design).width(numberWidth)
    }

    func label(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension TicketKind {
    var style: TicketStyle {
        switch self {
        case .flight:
            TicketStyle(
                background: Color(hex: "#E6F1FB"), ink: Color(hex: "#042C53"), muted: Color(hex: "#185FA5"), accent: Color(hex: "#185FA5"),
                perforation: Color(hex: "#85B7EB"), design: .monospaced,
                stubFill: Color(hex: "#042C53"), stubInk: .white, stubMuted: Color(hex: "#85B7EB")
            )
        case .concert:
            TicketStyle(
                background: Color(hex: "#26215C"), ink: .white, muted: Color(hex: "#AFA9EC"), accent: Color(hex: "#F4C0D1"),
                perforation: Color(hex: "#534AB7"), design: .default, numberWidth: .compressed,
                stubFill: Color(hex: "#F4C0D1"), stubInk: Color(hex: "#26215C"), stubMuted: Color(hex: "#534AB7")
            )
        case .exam:
            TicketStyle(
                background: Color(hex: "#F1EFE8"), ink: Color(hex: "#2C2C2A"), muted: Color(hex: "#5F5E5A"), accent: Color(hex: "#A32D2D"),
                perforation: Color(hex: "#B4B2A9"), design: .monospaced,
                stubFill: Color(hex: "#2C2C2A"), stubInk: .white, stubMuted: Color(hex: "#B4B2A9")
            )
        case .wedding:
            TicketStyle(
                background: Color(hex: "#FBEAF0"), ink: Color(hex: "#4B1528"), muted: Color(hex: "#993556"), accent: Color(hex: "#D4537E"),
                perforation: Color(hex: "#ED93B1"), design: .serif,
                stubFill: Color(hex: "#72243E"), stubInk: .white, stubMuted: Color(hex: "#F4C0D1")
            )
        case .birthday:
            TicketStyle(
                background: Color(hex: "#FAEEDA"), ink: Color(hex: "#412402"), muted: Color(hex: "#854F0B"), accent: Color(hex: "#BA7517"),
                perforation: Color(hex: "#EF9F27"), design: .rounded,
                stubFill: Color(hex: "#EF9F27"), stubInk: Color(hex: "#412402"), stubMuted: Color(hex: "#633806"),
                // The cake poster has a pale cream sky right behind the title.
                scrim: 1.7
            )
        case .holiday:
            TicketStyle(
                background: Color(hex: "#791F1F"), ink: .white, muted: Color(hex: "#F7C1C1"), accent: Color(hex: "#F09595"),
                perforation: Color(hex: "#E24B4A"), design: .monospaced,
                stubFill: Color(hex: "#0F3D33"), stubInk: Color(hex: "#FAEEDA"), stubMuted: Color(hex: "#F09595")
            )
        }
    }

    /// The small print in the ticket's top corner.
    var ticketLabel: String {
        switch self {
        case .flight: String(localized: "BOARDING PASS", bundle: .app)
        case .concert: String(localized: "LIVE · ADMIT ONE", bundle: .app)
        case .exam: String(localized: "EXAM ENTRY SLIP", bundle: .app)
        case .wedding: String(localized: "INVITATION", bundle: .app)
        case .birthday: String(localized: "PARTY PASS", bundle: .app)
        case .holiday: String(localized: "EXPRESS", bundle: .app)
        }
    }
}
