import SwiftUI

extension Color {
    /// Creates a colour from "#RRGGBB" or "RRGGBB". Invalid input falls back to grey.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = .gray
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
