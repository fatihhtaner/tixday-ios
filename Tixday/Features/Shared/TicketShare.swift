import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// A ticket shared as a picture. The image is only drawn when the user actually shares it, so a
/// share button costs nothing until it's used.
struct TicketShareCard: Transferable {
    let ticket: TicketSnapshot

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            await card.image().pngData() ?? Data()
        }
    }

    @MainActor
    func image() -> UIImage {
        let renderer = ImageRenderer(
            content: TicketView(ticket: ticket, size: .medium, notchColor: nil)
                .frame(width: 360, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(20)
                .appLanguage()
        )
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }
}
