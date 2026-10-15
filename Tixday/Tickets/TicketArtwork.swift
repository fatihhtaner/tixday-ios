import SwiftUI
import UIKit

/// Decodes ticket photos once and keeps them, since views ask for them on every redraw.
enum TicketPhoto {
    private static let cache = NSCache<NSData, UIImage>()

    static func image(_ data: Data?) -> Image? {
        guard let data else { return nil }
        let key = data as NSData
        if let cached = cache.object(forKey: key) { return Image(uiImage: cached) }
        guard let decoded = UIImage(data: data) else { return nil }
        cache.setObject(decoded, forKey: key)
        return Image(uiImage: decoded)
    }
}

extension TicketSnapshot {
    /// What fills the ticket body: the user's photo, or the kind's poster.
    func artwork(_ shape: TicketPoster.Shape) -> Image? {
        TicketPhoto.image(photoData) ?? TicketPoster.image(kind, shape)
    }

    /// Posters keep their subject on the right; a photo was framed by the user, so it stays centred.
    func artworkAlignment(_ posterAlignment: Alignment) -> Alignment {
        photoData == nil ? posterAlignment : .center
    }
}
