import SwiftUI

/// Poster artwork for a kind, when it has one: vivid illustration that fills the ticket body.
enum TicketPoster {
    enum Shape: String { case wide, square }

    static func image(_ kind: TicketKind, _ shape: Shape) -> Image? {
        let name = "poster-\(kind.rawValue)-\(shape.rawValue)"
        return UIImage(named: name) == nil ? nil : Image(name)
    }
}

/// Ticket v3: the poster (later the user's photo) is the ticket body, with white type over it and a solid
/// coloured stub carrying the count.
struct PosterTicketView: View {
    var ticket: TicketSnapshot
    var size: TicketView.Size
    var poster: Image
    var days: Int
    var progress: Double
    var notchColor: Color?

    private var style: TicketStyle { ticket.kind.style }

    var body: some View {
        switch size {
        case .small: small
        case .medium: medium
        }
    }

    // MARK: - Medium

    private var medium: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                PosterFill(image: poster, alignment: .trailing)
                Scrim()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(ticket.kind.ticketLabel)
                        Spacer()
                        Image(systemName: ticket.kind.symbol)
                    }
                    .font(style.label(10, weight: .bold))
                    .opacity(0.92)

                    Spacer(minLength: 4)

                    // Title sits low, over the darker foot of the artwork, like a film poster.
                    headline

                    WaitProgressBar(progress: progress, track: .white.opacity(0.3), fill: .white)
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
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                .padding(14)
            }

            Perforation(axis: .vertical, color: style.posterStubMuted.opacity(0.6))
                .background(style.posterStub)

            VStack(spacing: 2) {
                Text(CountLabel.number(for: days))
                    .font(style.number(46))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(CountLabel.text(for: days))
                    .font(style.label(11, weight: .bold))
                    .foregroundStyle(style.posterStubMuted)
            }
            .foregroundStyle(style.posterStubInk)
            .frame(width: 104)
            .padding(.horizontal, 4)
            .frame(maxHeight: .infinity)
            .background(style.posterStub)
        }
        .overlay(alignment: .trailing) {
            Notches(axis: .vertical, color: notchColor)
                .frame(width: 14)
                .padding(.trailing, 105)
        }
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
                .font(style.number(24))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: - Small

    private var small: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                PosterFill(image: poster, alignment: .topTrailing)
                Scrim()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(ticket.kind.ticketLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        Image(systemName: ticket.kind.symbol)
                    }
                    .font(style.label(10, weight: .bold))
                    .opacity(0.92)

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
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                .padding([.horizontal, .top], 12)
                .padding(.bottom, 6)
            }

            // Solid tear-off strip, so it still reads as a ticket.
            HStack {
                Text(ticket.kind.showsRoute && !ticket.destination.isEmpty ? ticket.destination : (ticket.headline.isEmpty ? ticket.title : ticket.headline))
                Spacer(minLength: 4)
                Text(ticket.date.stubText)
            }
            .font(style.label(10, weight: .semibold))
            .foregroundStyle(style.posterStubInk)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(style.posterStub)
            .overlay(alignment: .top) {
                ZStack {
                    Perforation(axis: .horizontal, color: style.posterStubMuted.opacity(0.6))
                    Notches(axis: .horizontal, color: notchColor)
                }
                .frame(height: 14)
                .offset(y: -7)
            }
        }
    }
}

/// Darkens the top and bottom of the artwork just enough for white type.
private struct Scrim: View {
    var body: some View {
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
        .allowsHitTesting(false)
    }
}

/// Fills its frame with an image, cropping the overflow.
private struct PosterFill: View {
    var image: Image
    var alignment: Alignment

    var body: some View {
        GeometryReader { proxy in
            image
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: alignment)
                .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
