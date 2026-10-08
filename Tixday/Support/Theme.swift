import SwiftUI

/// App chrome around the tickets: a warm paper canvas and an expanded display face for headings.
enum Theme {
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "#111113")) : UIColor(Color(hex: "#F3F1EC"))
    })
    static let card = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "#1D1D20")) : .white
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "#F3F1EC")) : UIColor(Color(hex: "#16161A"))
    })

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.expanded)
    }

    /// Small spaced-out caps used for section labels.
    static let eyebrow = Font.system(size: 12, weight: .semibold).width(.expanded)
}

extension View {
    /// Soft lift under a ticket, following its punched outline.
    func ticketShadow() -> some View {
        shadow(color: .black.opacity(0.10), radius: 14, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}
