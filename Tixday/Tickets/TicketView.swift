import SwiftUI

/// A countdown drawn as a ticket. Fills whatever frame it is given: a widget, or a card in the app.
/// The body is the kind's poster (later the user's photo), or its paper colour and decoration until
/// it has one; a solid tear-off stub carries the count.
struct TicketView: View {
    enum Size { case small, medium }

    var ticket: TicketSnapshot
    var size: Size
    var now: Date = .now
    /// Fill for the notches. nil cuts real holes (in the app); widgets can't, so they paint a darker tone.
    var notchColor: Color? = .black.opacity(0.22)

    private var style: TicketStyle { ticket.kind.style }
    private var days: Int { DayCount.days(until: ticket.date, from: now) }
    private var poster: Image? { TicketPoster.image(ticket.kind, size == .small ? .square : .wide) }
    /// White type with a soft shadow over artwork; the kind's ink on plain paper.
    private var bodyInk: Color { poster == nil ? style.ink : .white }

    var body: some View {
        Group {
            switch size {
            case .small: small
            case .medium: medium
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .compositingGroup()
    }

    // MARK: - Medium

    /// Ticket body on the left, tear-off stub with the count on the right.
    private var medium: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TicketBody(kind: ticket.kind, poster: poster, posterAlignment: .trailing)
                VStack(alignment: .leading, spacing: 0) {
                    labelRow
                    Spacer(minLength: 4)
                    // The title sits low, over the darker foot of the artwork, like a film poster.
                    headline
                    WaitProgressBar(
                        progress: DayCount.progress(createdAt: ticket.createdAt, target: ticket.date, now: now),
                        track: bodyInk.opacity(0.25),
                        fill: bodyInk
                    )
                    .frame(maxWidth: 150)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    HStack(spacing: 12) {
                        if !ticket.stubLeft.isEmpty { Text(ticket.stubLeft) }
                        if !ticket.stubRight.isEmpty { Text(ticket.stubRight) }
                        Text(ticket.date.stubText)
                    }
                    .font(style.label(11))
                    .lineLimit(1)
                    .opacity(0.92)
                }
                .foregroundStyle(bodyInk)
                .shadow(color: .black.opacity(poster == nil ? 0 : 0.35), radius: 3, y: 1)
                .padding(14)
            }

            Perforation(axis: .vertical, color: style.stubMuted.opacity(0.6))
                .background(style.stubFill)

            VStack(spacing: 2) {
                Text(CountLabel.number(for: days))
                    .font(style.number(46))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(CountLabel.text(for: days))
                    .font(style.label(11, weight: .bold))
                    .foregroundStyle(style.stubMuted)
            }
            .foregroundStyle(style.stubInk)
            .frame(width: 104)
            .padding(.horizontal, 4)
            .frame(maxHeight: .infinity)
            .background(style.stubFill)
        }
        .overlay(alignment: .trailing) {
            Notches(axis: .vertical, color: notchColor)
                .frame(width: 14)
                .padding(.trailing, 105)
        }
    }

    // MARK: - Small

    /// Square body with the count in its lower left, over a solid tear-off strip.
    private var small: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TicketBody(kind: ticket.kind, poster: poster, posterAlignment: .topTrailing)
                VStack(alignment: .leading, spacing: 0) {
                    labelRow
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(CountLabel.number(for: days))
                            .font(style.number(44))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(CountLabel.text(for: days))
                            .font(style.label(10, weight: .bold))
                    }
                }
                .foregroundStyle(bodyInk)
                .shadow(color: .black.opacity(poster == nil ? 0 : 0.4), radius: 3, y: 1)
                .padding([.horizontal, .top], 12)
                .padding(.bottom, 6)
            }

            HStack {
                Text(shortName)
                Spacer(minLength: 4)
                Text(ticket.date.stubText)
            }
            .font(style.label(10, weight: .semibold))
            .foregroundStyle(style.stubInk)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(style.stubFill)
            .overlay(alignment: .top) {
                ZStack {
                    Perforation(axis: .horizontal, color: style.stubMuted.opacity(0.6))
                    Notches(axis: .horizontal, color: notchColor)
                }
                .frame(height: 14)
                .offset(y: -7)
            }
        }
    }

    // MARK: - Pieces

    private var labelRow: some View {
        HStack {
            Text(ticket.kind.ticketLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Image(systemName: ticket.kind.symbol)
        }
        .font(style.label(10, weight: .bold))
        .opacity(0.92)
    }

    @ViewBuilder
    private var headline: some View {
        if ticket.kind.showsRoute && !ticket.origin.isEmpty && !ticket.destination.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(ticket.origin)
                Image(systemName: ticket.kind == .flight ? "airplane" : "arrow.right")
                    .font(style.label(14, weight: .bold))
                Text(ticket.destination)
            }
            .font(style.number(26))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            Text(ticket.headline.isEmpty ? ticket.title : ticket.headline)
                .font(ticket.kind == .wedding ? style.label(24).italic() : style.number(24))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    /// Destination for travel, otherwise the headline or title; fits the small stub strip.
    private var shortName: String {
        if ticket.kind.showsRoute && !ticket.destination.isEmpty { return ticket.destination }
        return ticket.headline.isEmpty ? ticket.title : ticket.headline
    }
}

/// Poster artwork for a kind, when it has one: vivid illustration that fills the ticket body.
enum TicketPoster {
    enum Shape: String { case wide, square }

    static func image(_ kind: TicketKind, _ shape: Shape) -> Image? {
        let name = "poster-\(kind.rawValue)-\(shape.rawValue)"
        return UIImage(named: name) == nil ? nil : Image(name)
    }
}

/// The ticket body: poster with a scrim for white type, or the kind's paper with its corner decoration.
struct TicketBody: View {
    var kind: TicketKind
    var poster: Image?
    var posterAlignment: Alignment

    var body: some View {
        if let poster {
            ZStack {
                GeometryReader { proxy in
                    poster
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: posterAlignment)
                        .clipped()
                }
                // Darkens the top and bottom just enough for white type.
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.32), location: 0),
                        .init(color: .black.opacity(0), location: 0.38),
                        .init(color: .black.opacity(0), location: 0.55),
                        .init(color: .black.opacity(0.5), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            kind.style.background
                .overlay(alignment: .bottomTrailing) {
                    Image("art-\(kind.rawValue)")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.25, anchor: .bottomTrailing)
                        .opacity(kind.style.artOpacity)
                        .accessibilityHidden(true)
                }
                .clipped()
        }
    }
}

#Preview("Small") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 158))], spacing: 16) {
        ForEach(TicketSnapshot.samples()) { ticket in
            TicketView(ticket: ticket, size: .small, notchColor: nil)
                .frame(width: 158, height: 158)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
    .padding()
}

#Preview("Medium") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(TicketSnapshot.samples()) { ticket in
                TicketView(ticket: ticket, size: .medium, notchColor: nil)
                    .frame(width: 338, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
        .padding()
    }
}
