import SwiftUI

/// The next ticket, big: artwork on top, and a stub with the day count and a live clock to the day.
struct HeroTicket: View {
    let ticket: TicketSnapshot

    private var style: TicketStyle { ticket.kind.style }
    private var poster: Image? { TicketPoster.image(ticket.kind, .wide) }
    private var bodyInk: Color { poster == nil ? style.ink : .white }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TicketBody(kind: ticket.kind, poster: poster, posterAlignment: .trailing)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ticket.kind.ticketLabel)
                        Spacer()
                        Image(systemName: ticket.kind.symbol)
                    }
                    .font(style.label(11, weight: .bold))
                    .opacity(0.92)
                    Spacer(minLength: 0)
                    TicketHeadline(ticket: ticket, size: 30)
                    Text([ticket.stubLeft, ticket.stubRight, ticket.date.stubText].filter { !$0.isEmpty }.joined(separator: "   "))
                        .font(style.label(12))
                        .lineLimit(1)
                        .opacity(0.92)
                }
                .foregroundStyle(bodyInk)
                .shadow(color: .black.opacity(poster == nil ? 0 : 0.35), radius: 3, y: 1)
                .padding(18)
            }
            .frame(height: 220)

            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    let days = DayCount.days(until: ticket.date)
                    Text(CountLabel.number(for: days))
                        .font(style.number(44))
                        .contentTransition(.numericText())
                    Text(CountLabel.text(for: days))
                        .font(style.label(12, weight: .bold))
                        .foregroundStyle(style.stubMuted)
                }
                Spacer()
                LiveClock(target: ticket.date)
                    .font(style.label(17, weight: .semibold).monospacedDigit())
                    .foregroundStyle(style.stubMuted)
            }
            .foregroundStyle(style.stubInk)
            .padding(.horizontal, 18)
            .frame(height: 76)
            .background(style.stubFill)
            .overlay(alignment: .top) { TearLine(style: style) }
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .ticketShadow()
    }
}

/// One ticket in the wallet stack. Closed, only its coloured header shows and the rest is filled
/// with the header colour (so the next card's rounded corners don't reveal artwork underneath);
/// open, the artwork shows below a tear line.
struct WalletCard: View {
    let ticket: TicketSnapshot
    var isOpen: Bool

    static let headerHeight: CGFloat = 68
    static let openHeight: CGFloat = 188
    /// How far the next card covers this one: enough to hide the bottom corners.
    static let overlap: CGFloat = 26

    private var style: TicketStyle { ticket.kind.style }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(ticket.kind.ticketLabel, systemImage: ticket.kind.symbol)
                        .font(style.label(10, weight: .bold))
                        .foregroundStyle(style.stubMuted)
                        .lineLimit(1)
                    Text(ticket.title)
                        .font(ticket.kind == .wedding ? style.label(19).italic() : style.number(19))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                let days = DayCount.days(until: ticket.date)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(CountLabel.number(for: days))
                        .font(style.number(28))
                    Text(CountLabel.text(for: days))
                        .font(style.label(9, weight: .bold))
                        .foregroundStyle(style.stubMuted)
                }
            }
            .foregroundStyle(style.stubInk)
            .padding(.horizontal, 16)
            .frame(height: Self.headerHeight)

            ZStack(alignment: .top) {
                TicketBody(kind: ticket.kind, poster: TicketPoster.image(ticket.kind, .wide), posterAlignment: .trailing)
                    .opacity(isOpen ? 1 : 0)
                // Notches painted in the canvas colour: a real cut-out would show the cards beneath.
                TearLine(style: style, notchColor: Theme.canvas)
                    .opacity(isOpen ? 1 : 0)
            }
            .frame(height: Self.openHeight - Self.headerHeight)
        }
        .background(style.stubFill)
        .frame(height: isOpen ? Self.openHeight : Self.headerHeight + Self.overlap, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 10, y: -2)
    }
}

/// Route for travel, otherwise the headline or title.
struct TicketHeadline: View {
    let ticket: TicketSnapshot
    var size: CGFloat

    private var style: TicketStyle { ticket.kind.style }

    var body: some View {
        if ticket.kind.showsRoute && !ticket.origin.isEmpty && !ticket.destination.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(ticket.origin)
                Image(systemName: ticket.kind == .flight ? "airplane" : "arrow.right")
                    .font(style.label(size * 0.55, weight: .bold))
                Text(ticket.destination)
            }
            .font(style.number(size))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            Text(ticket.headline.isEmpty ? ticket.title : ticket.headline)
                .font(ticket.kind == .wedding ? style.label(size).italic() : style.number(size))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }
}

/// Hours, minutes and seconds left today before the count drops, ticking every second.
private struct LiveClock: View {
    let target: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let start = Calendar.current.startOfDay(for: target)
            let remaining = max(Int(start.timeIntervalSince(context.date)), 0) % 86_400
            Text(String(format: "%02d:%02d:%02d", remaining / 3_600, remaining % 3_600 / 60, remaining % 60))
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: remaining)
        }
    }
}

/// Dashed tear line with punched notches, laid across the top edge of a stub.
private struct TearLine: View {
    let style: TicketStyle
    /// nil punches real holes.
    var notchColor: Color? = nil

    var body: some View {
        ZStack {
            Perforation(axis: .horizontal, color: style.stubMuted.opacity(0.6))
            Notches(axis: .horizontal, color: notchColor)
        }
        .frame(height: 14)
        .offset(y: -7)
    }
}
