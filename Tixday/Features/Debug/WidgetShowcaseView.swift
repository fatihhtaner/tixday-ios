#if DEBUG
import SwiftUI

/// A Home Screen page with Tixday's widgets on a wallpaper, for the App Store screenshot of widgets.
/// The widgets are the real `TicketView`s the widget extension draws. Open with `-screenshotScreen widgets`.
struct WidgetShowcaseView: View {
    /// Tickets to show; the samples when nil. The first one gets the big widgets.
    var tickets: [TicketSnapshot]?

    private var samples: [TicketSnapshot] {
        guard let tickets, let first = tickets.first else { return TicketSnapshot.samples() }
        // Same layout as the samples: the user's tickets first, samples filling the rest.
        // The user's first ticket as the big widget and a small one; samples fill the rest of the page.
        var list = TicketSnapshot.samples()
        list[0] = first
        list[1] = first
        return list
    }

    var body: some View {
        GeometryReader { proxy in
            let side = (proxy.size.width - 3 * 26) / 2
            VStack(spacing: 26) {
                widget(samples[0], size: .medium)
                    .frame(height: side)
                HStack(spacing: 26) {
                    widget(samples[1], size: .small).frame(width: side, height: side)
                    widget(samples[4], size: .small).frame(width: side, height: side)
                }
                widget(samples[5], size: .medium)
                    .frame(height: side)
                HStack(spacing: 26) {
                    widget(samples[2], size: .small).frame(width: side, height: side)
                    widget(samples[3], size: .small).frame(width: side, height: side)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
            .padding(.top, 70)
        }
        .background {
            TicketPoster.image(.holiday, .wide)?
                .resizable()
                .scaledToFill()
                .blur(radius: 24)
                .overlay(Color.black.opacity(0.25))
                .ignoresSafeArea()
        }
        .appLanguage()
    }

    private func widget(_ ticket: TicketSnapshot, size: TicketView.Size) -> some View {
        TicketView(ticket: ticket, size: size)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
}
#endif
