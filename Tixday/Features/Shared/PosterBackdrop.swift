import SwiftUI

/// A ticket kind's poster, blurred and darkened into an atmosphere behind a whole screen.
struct PosterBackdrop: View {
    var kind: TicketKind?

    var body: some View {
        ZStack {
            Color.black
            if let kind {
                Group {
                    if let poster = TicketPoster.image(kind, .square) {
                        poster
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 50)
                            .scaleEffect(1.3)
                    } else {
                        kind.style.background
                    }
                }
                .id(kind)
                .transition(.opacity)
            }
            Color.black.opacity(0.45)
        }
        .animation(.easeInOut(duration: 0.45), value: kind)
        .ignoresSafeArea()
    }
}
