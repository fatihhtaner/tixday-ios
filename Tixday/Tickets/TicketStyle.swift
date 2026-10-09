import SwiftUI

/// Colours and type for one ticket design.
struct TicketStyle {
    var background: Color
    /// Coloured band at the top of the ticket, if the design has one.
    var band: Color?
    var bandInk: Color
    var ink: Color
    var muted: Color
    var accent: Color
    var perforation: Color
    var design: Font.Design
    var numberWidth: Font.Width = .standard
    /// How strongly the decoration shows through; tuned per design so text stays readable.
    var artOpacity: Double = 0.5
    /// Solid stub beside a poster or photo (v3 tickets); defaults to the classic paper colours.
    var posterStubColors: (fill: Color, ink: Color, muted: Color)?

    var posterStub: Color { posterStubColors?.fill ?? background }
    var posterStubInk: Color { posterStubColors?.ink ?? ink }
    var posterStubMuted: Color { posterStubColors?.muted ?? muted }

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
                background: Color(hex: "#E6F1FB"), band: Color(hex: "#185FA5"), bandInk: Color(hex: "#E6F1FB"),
                ink: Color(hex: "#042C53"), muted: Color(hex: "#185FA5"), accent: Color(hex: "#185FA5"),
                perforation: Color(hex: "#85B7EB"), design: .monospaced, artOpacity: 0.75,
                posterStubColors: (Color(hex: "#042C53"), .white, Color(hex: "#85B7EB"))
            )
        case .concert:
            TicketStyle(
                background: Color(hex: "#26215C"), band: nil, bandInk: .white,
                ink: .white, muted: Color(hex: "#AFA9EC"), accent: Color(hex: "#F4C0D1"),
                perforation: Color(hex: "#534AB7"), design: .default, numberWidth: .compressed, artOpacity: 0.75
            )
        case .exam:
            TicketStyle(
                background: Color(hex: "#F1EFE8"), band: nil, bandInk: .black,
                ink: Color(hex: "#2C2C2A"), muted: Color(hex: "#5F5E5A"), accent: Color(hex: "#A32D2D"),
                perforation: Color(hex: "#B4B2A9"), design: .monospaced, artOpacity: 0.7
            )
        case .wedding:
            TicketStyle(
                background: Color(hex: "#FBEAF0"), band: nil, bandInk: .black,
                ink: Color(hex: "#4B1528"), muted: Color(hex: "#993556"), accent: Color(hex: "#D4537E"),
                perforation: Color(hex: "#ED93B1"), design: .serif, artOpacity: 0.65
            )
        case .birthday:
            TicketStyle(
                background: Color(hex: "#FAEEDA"), band: nil, bandInk: .black,
                ink: Color(hex: "#412402"), muted: Color(hex: "#854F0B"), accent: Color(hex: "#BA7517"),
                perforation: Color(hex: "#EF9F27"), design: .rounded, artOpacity: 0.75
            )
        case .holiday:
            TicketStyle(
                background: Color(hex: "#791F1F"), band: nil, bandInk: .white,
                ink: .white, muted: Color(hex: "#F7C1C1"), accent: Color(hex: "#F09595"),
                perforation: Color(hex: "#E24B4A"), design: .monospaced, artOpacity: 0.8
            )
        }
    }

    /// The small print in the ticket's top corner.
    var ticketLabel: String {
        switch self {
        case .flight: String(localized: "BOARDING PASS")
        case .concert: String(localized: "LIVE · ADMIT ONE")
        case .exam: String(localized: "EXAM ENTRY SLIP")
        case .wedding: String(localized: "INVITATION")
        case .birthday: String(localized: "PARTY PASS")
        case .holiday: String(localized: "EXPRESS")
        }
    }
}
