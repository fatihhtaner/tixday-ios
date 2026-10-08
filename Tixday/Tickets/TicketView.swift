import SwiftUI

/// A countdown drawn as a ticket. Fills whatever frame it is given: a widget, or a card in the app.
struct TicketView: View {
    enum Size { case small, medium }

    var ticket: TicketSnapshot
    var size: Size
    var now: Date = .now
    /// Fill for the notches. nil cuts real holes (in the app); widgets can't, so they paint a darker tone.
    var notchColor: Color? = .black.opacity(0.22)

    private var style: TicketStyle { ticket.kind.style }
    private var days: Int { DayCount.days(until: ticket.date, from: now) }

    var body: some View {
        Group {
            switch size {
            case .small: small
            case .medium: medium
            }
        }
        .foregroundStyle(style.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .bottomTrailing) {
            if size == .small {
                TicketArt(kind: ticket.kind)
                    .padding(.bottom, ticket.kind.hasStubFooter ? 30 : 0)
                    .padding(.trailing, ticket.kind == .birthday ? 30 : 0)
            }
        }
        .background(style.background)
        .compositingGroup()
    }

    // MARK: - Small

    @ViewBuilder
    private var small: some View {
        switch ticket.kind {
        case .flight: SmallFlight(ticket: ticket, days: days, style: style, notchColor: notchColor)
        case .concert: SmallConcert(ticket: ticket, days: days, style: style, notchColor: notchColor)
        case .exam: SmallExam(ticket: ticket, days: days, style: style)
        case .wedding: SmallWedding(ticket: ticket, days: days, style: style)
        case .birthday: SmallBirthday(ticket: ticket, days: days, style: style, notchColor: notchColor)
        case .holiday: SmallHoliday(ticket: ticket, days: days, style: style, notchColor: notchColor)
        }
    }

    // MARK: - Medium

    /// Ticket on the left, tear-off stub with the count on the right.
    private var medium: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header
                VStack(alignment: .leading, spacing: 6) {
                    mainLine
                    WaitProgressBar(
                        progress: DayCount.progress(createdAt: ticket.createdAt, target: ticket.date, now: now),
                        track: style.perforation.opacity(0.45),
                        fill: style.accent
                    )
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                Spacer(minLength: 4)
                HStack(spacing: 14) {
                    if !ticket.stubLeft.isEmpty { Text(ticket.stubLeft) }
                    if !ticket.stubRight.isEmpty { Text(ticket.stubRight) }
                    Text(ticket.date.stubText)
                }
                .font(style.label(11))
                .foregroundStyle(style.muted)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(alignment: .bottomTrailing) {
                TicketArt(kind: ticket.kind).padding(.bottom, 30)
            }
            Perforation(axis: .vertical, color: style.perforation)
            VStack(spacing: 2) {
                Text(CountLabel.number(for: days))
                    .font(style.number(46))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(CountLabel.text(for: days))
                    .font(style.label(11, weight: .bold))
                    .foregroundStyle(style.muted)
            }
            .frame(width: 104)
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .trailing) {
            Notches(axis: .vertical, color: notchColor)
                .frame(width: 14)
                .padding(.trailing, 105)
        }
    }

    private var header: some View {
        HStack {
            Text(ticket.kind.ticketLabel)
            Spacer()
            Image(systemName: ticket.kind.symbol)
        }
        .font(style.label(11, weight: .bold))
        .foregroundStyle(style.band == nil ? style.muted : style.bandInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(style.band ?? .clear)
        .padding(.top, style.band == nil ? 4 : 0)
    }

    @ViewBuilder
    private var mainLine: some View {
        if ticket.kind.showsRoute && !ticket.origin.isEmpty && !ticket.destination.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(ticket.origin)
                Image(systemName: ticket.kind == .flight ? "airplane" : "arrow.right")
                    .font(style.label(13))
                    .foregroundStyle(style.accent)
                Text(ticket.destination)
            }
            .font(style.number(24))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            Text(ticket.headline.isEmpty ? ticket.title : ticket.headline)
                .font(ticket.kind == .wedding ? style.label(22).italic() : style.number(24))
                .foregroundStyle(ticket.kind == .concert ? style.accent : style.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Small designs

private struct SmallFlight: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle
    var notchColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(ticket.kind.ticketLabel)
                Spacer()
                Image(systemName: ticket.kind.symbol)
            }
            .font(style.label(10, weight: .bold))
            .foregroundStyle(style.bandInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(style.band)

            HStack {
                Text(ticket.origin.isEmpty ? "—" : ticket.origin)
                Spacer()
                Image(systemName: "airplane").font(style.label(10))
                Spacer()
                Text(ticket.destination.isEmpty ? "—" : ticket.destination)
            }
            .font(style.label(12, weight: .bold))
            .foregroundStyle(style.muted)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            CountBlock(days: days, style: style, size: 38)
                .padding(.horizontal, 12)

            Spacer(minLength: 0)
            StubFooter(left: ticket.stubLeft, right: ticket.date.stubText, style: style, notchColor: notchColor)
        }
    }
}

private struct SmallConcert: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle
    var notchColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ticket.kind.ticketLabel)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(style.muted)
            Text((ticket.headline.isEmpty ? ticket.title : ticket.headline).uppercased())
                .font(.system(size: 24, weight: .heavy).width(.compressed))
                .foregroundStyle(style.accent)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            CountBlock(days: days, style: style, size: 46)
            Spacer(minLength: 0)
        }
        .padding([.horizontal, .top], 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            StubFooter(left: ticket.stubLeft, right: ticket.stubRight, style: style, notchColor: notchColor)
        }
    }
}

private struct SmallExam: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ticket.kind.ticketLabel)
                .font(style.label(10, weight: .bold))
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(style.muted, lineWidth: 1)
                    .frame(width: 26, height: 32)
                    .overlay(Image(systemName: "person").font(.system(size: 13)).foregroundStyle(style.muted))
                VStack(alignment: .leading, spacing: 1) {
                    Text(ticket.headline.isEmpty ? ticket.title : ticket.headline)
                    if !ticket.stubLeft.isEmpty { Text(ticket.stubLeft) }
                }
                .font(style.label(10))
                .foregroundStyle(style.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            CountBlock(days: days, style: style, size: 38)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            Text(String(localized: "APPROVED"))
                .font(style.label(9, weight: .bold))
                .foregroundStyle(style.accent)
                .frame(width: 50, height: 50)
                .overlay(Circle().stroke(style.accent, lineWidth: 2))
                .rotationEffect(.degrees(-14))
                .padding(10)
        }
    }
}

private struct SmallWedding: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle

    var body: some View {
        VStack(spacing: 2) {
            Text(ticket.kind.ticketLabel)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(style.muted)
            Text(ticket.headline.isEmpty ? ticket.title : ticket.headline)
                .font(style.label(15).italic())
                .foregroundStyle(style.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(CountLabel.number(for: days))
                .font(.system(size: 44, weight: .medium, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(days > 0 ? String(localized: "days to go") : CountLabel.text(for: days).lowercased())
                .font(style.label(12).italic())
                .foregroundStyle(style.muted)
            Image(systemName: "heart")
                .font(.system(size: 12))
                .foregroundStyle(style.accent)
                .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style.accent.opacity(0.6), lineWidth: 0.75)
                .padding(7)
        )
    }
}

private struct SmallBirthday: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle
    var notchColor: Color?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.kind.ticketLabel)
                    .font(style.label(10, weight: .bold))
                    .foregroundStyle(style.muted)
                Image(systemName: ticket.kind.symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(style.accent)
                Spacer(minLength: 0)
                Text(CountLabel.number(for: days))
                    .font(style.number(38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text([CountLabel.text(for: days).lowercased(), ticket.headline].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(style.label(11))
                    .foregroundStyle(style.muted)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Perforation(axis: .vertical, color: style.perforation)
            Text(ticket.stubLeft.isEmpty ? ticket.date.stubText : ticket.stubLeft)
                .font(style.label(10, weight: .bold))
                .foregroundStyle(style.ink)
                .lineLimit(1)
                .fixedSize()
                .rotationEffect(.degrees(90))
                .frame(width: 30)
                .frame(maxHeight: .infinity)
                .background(style.perforation.opacity(0.45))
        }
        .overlay(alignment: .trailing) {
            Notches(axis: .vertical, color: notchColor).frame(width: 14).padding(.trailing, 24)
        }
    }
}

private struct SmallHoliday: View {
    var ticket: TicketSnapshot
    var days: Int
    var style: TicketStyle
    var notchColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(ticket.kind.ticketLabel)
                Spacer()
                Image(systemName: ticket.kind.symbol)
            }
            .font(style.label(10, weight: .bold))
            .foregroundStyle(style.accent)
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Text("→ " + (ticket.destination.isEmpty ? ticket.headline : ticket.destination).uppercased())
                .font(style.label(12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            CountBlock(days: days, style: style, size: 38)
                .padding(.horizontal, 12)

            Spacer(minLength: 0)
            StubFooter(left: ticket.stubLeft, right: ticket.date.stubText, style: style, notchColor: notchColor)
        }
    }
}

// MARK: - Shared pieces

private extension TicketKind {
    /// Small designs with a tear line and small print along the bottom; the art sits above it.
    var hasStubFooter: Bool { self == .flight || self == .concert || self == .holiday }
}

/// The kind's illustrated decoration, sitting tone-on-tone in the bottom corner behind the text.
private struct TicketArt: View {
    var kind: TicketKind

    var body: some View {
        Image("art-\(kind.rawValue)")
            .resizable()
            .scaledToFit()
            .scaleEffect(1.25, anchor: .bottomTrailing)
            .opacity(kind.style.artOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Big number with its unit beside it: "83 DAYS".
private struct CountBlock: View {
    var days: Int
    var style: TicketStyle
    var size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(CountLabel.number(for: days))
                .font(style.number(size))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(CountLabel.text(for: days))
                .font(style.label(10, weight: .bold))
                .foregroundStyle(style.muted)
        }
    }
}

/// Dashed tear line with small print below it.
private struct StubFooter: View {
    var left: String
    var right: String
    var style: TicketStyle
    var notchColor: Color?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Perforation(axis: .horizontal, color: style.perforation)
                Notches(axis: .horizontal, color: notchColor)
            }
            .frame(height: 14)
            HStack {
                Text(left)
                Spacer()
                Text(right)
            }
            .font(style.label(10))
            .foregroundStyle(style.muted)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.bottom, 9)
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
