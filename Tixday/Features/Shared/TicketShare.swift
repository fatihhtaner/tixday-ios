import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// A ticket shared as a picture, signed with a small Tixday mark so every share is an introduction.
/// The image is only drawn when the user actually shares it, so a share button costs nothing until it's used.
struct TicketShareCard: Transferable {
    let ticket: TicketSnapshot

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            await card.image().pngData() ?? Data()
        }
    }

    @MainActor
    func image() -> UIImage {
        let renderer = ImageRenderer(content: ShareCardView(ticket: ticket).appLanguage())
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }
}

/// The ticket on a dark card with "Made with Tixday" underneath.
private struct ShareCardView: View {
    let ticket: TicketSnapshot

    var body: some View {
        VStack(spacing: 14) {
            TicketView(ticket: ticket, size: .medium, notchColor: nil)
                .frame(width: 360, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            HStack(spacing: 6) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Made with Tixday")
                    .font(.system(size: 12, weight: .semibold).width(.expanded))
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .background(Color(hex: "#111113"))
        .environment(\.colorScheme, .dark)
    }
}
