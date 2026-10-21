// Renders static ads for Meta / TikTok / Pinterest: one promise per image, big short headline, the app's own
// tickets as the visual, logo + name and a visible CTA. Six variations per language:
//   1 widgets   – benefit: phone with Home Screen widgets
//   2 birthday  – benefit: the birthday ticket and "repeats every year"
//   3 before    – before / after: a plain note vs. a Tixday ticket
//   4 question  – question: a fan of tickets
//   5 trip      – benefit: boarding pass and train widgets
//   6 ticket    – brand line: the stamped ticket
// No social proof layout until the app has real ratings (made-up numbers break every ad network's rules).
//
// Usage: swift tools/make_static_ads.swift <raw-dir> <out-dir>
//   <raw-dir>/<lang>/{home,widgets,used}.png come from tools/capture_store_screens.sh (en and tr).
//   Writes <out-dir>/<lang>/<n>-<name>-{4x5,9x16}.jpg: 1080×1350 feed and 1080×1920 stories / TikTok.
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make_static_ads.swift <raw-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
let W: CGFloat = 1080

struct Copy {
    let tagline, cta, before, after, plainNote, plainDays, repeats: String
    let headlines: [String: (String, String?)]
}

/// `*word*` is drawn in the accent colour.
let copy: [String: Copy] = [
    "en": Copy(tagline: "Countdown Widgets", cta: "Download free", before: "BEFORE", after: "AFTER",
               plainNote: "Wedding – Mar 26", plainDays: "156 days left", repeats: "Repeats every year",
               headlines: [
                   "widgets": ("Every big day,\n*one glance* away", "Countdown widgets for your Home Screen"),
                   "birthday": ("Never forget\na *birthday* again", "Set it once. It counts down every year."),
                   "before": ("Same date.\n*Way more fun.*", nil),
                   "question": ("Still counting days\n*on your fingers?*", "Turn every date into a vintage ticket"),
                   "trip": ("Your *trip*,\nright on your\nHome Screen", "Watch the days fly by"),
                   "ticket": ("Every date\nis a *ticket*", "Concerts, trips, birthdays, weddings"),
               ]),
    "tr": Copy(tagline: "Geri Sayım Widget'ları", cta: "Ücretsiz indir", before: "ÖNCE", after: "SONRA",
               plainNote: "Düğün – 26 Mart", plainDays: "156 gün kaldı", repeats: "Her yıl tekrarlar",
               headlines: [
                   "widgets": ("Önemli günler\n*bir bakışta*", "Ana ekranın için geri sayım widget'ları"),
                   "birthday": ("Doğum günlerini\n*bir daha unutma*", "Bir kez kur, her yıl geri saysın."),
                   "before": ("Aynı tarih.\n*Çok daha keyifli.*", nil),
                   "question": ("Günleri hâlâ\n*parmakla* mı\nsayıyorsun?", "Her tarihi vintage bir bilete çevir"),
                   "trip": ("*Tatilin*\nana ekranında\ngeri sayıyor", "Günlerin nasıl geçtiğini izle"),
                   "ticket": ("Her tarih\nbir *bilet*", "Konser, tatil, doğum günü, düğün"),
               ]),
]

// MARK: - Basics (coordinates from the top left)

func hex(_ value: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255, alpha: alpha)
}
let yellow = hex(0xFFD84D)

func loadImage(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func bitmap(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let rounded = base.fontDescriptor.withDesign(.rounded) else { return base }
    return NSFont(descriptor: rounded, size: size) ?? base
}

/// A rounded piece of an image (rect in pixels from the top left).
func cut(_ image: CGImage, _ rect: CGRect, radius: CGFloat) -> CGImage {
    let piece = image.cropping(to: rect)!
    let cg = bitmap(piece.width, piece.height)
    let bounds = CGRect(x: 0, y: 0, width: piece.width, height: piece.height)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.draw(piece, in: bounds)
    return cg.makeImage()!
}

/// The phone: screen inside a dark bezel with a metal rim.
func phone(_ screen: CGImage, screenWidth: CGFloat) -> CGImage {
    let scale = screenWidth / CGFloat(screen.width)
    let screenHeight = CGFloat(screen.height) * scale
    let bezel: CGFloat = 16
    let size = CGSize(width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
    let cg = bitmap(Int(size.width), Int(size.height))
    let radius = 200 * scale
    let body = CGRect(origin: .zero, size: size)
    cg.addPath(CGPath(roundedRect: body, cornerWidth: radius + bezel, cornerHeight: radius + bezel, transform: nil))
    cg.setFillColor(hex(0x101014).cgColor)
    cg.fillPath()
    cg.addPath(CGPath(roundedRect: body.insetBy(dx: 2, dy: 2), cornerWidth: radius + bezel - 2, cornerHeight: radius + bezel - 2, transform: nil))
    cg.setStrokeColor(hex(0x8A8A94).cgColor)
    cg.setLineWidth(4)
    cg.strokePath()
    let screenRect = CGRect(x: bezel, y: bezel, width: screenWidth, height: screenHeight)
    cg.addPath(CGPath(roundedRect: screenRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.interpolationQuality = .high
    cg.draw(screen, in: screenRect)
    return cg.makeImage()!
}

let icon: CGImage = {
    let image = NSImage(contentsOf: root.appending(path: "Tixday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))!
    return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
}()

// MARK: - Canvas

final class Canvas {
    let H: CGFloat
    let cg: CGContext
    let locale: Locale
    /// Stories and TikTok cover the top and bottom with their own UI.
    var safeTop: CGFloat { H > 1500 ? 250 : 80 }
    var safeBottom: CGFloat { H > 1500 ? H - 330 : H - 70 }

    init(height: CGFloat, locale: Locale) {
        H = height
        self.locale = locale
        cg = bitmap(Int(W), Int(height))
        cg.translateBy(x: 0, y: height)
        cg.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    }

    func gradient(_ colors: [NSColor], locations: [CGFloat]? = nil) {
        let gradient = CGGradient(colorsSpace: sRGB, colors: colors.map(\.cgColor) as CFArray, locations: locations)!
        cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    }

    func glow(_ center: CGPoint, radius: CGFloat, alpha: CGFloat = 0.25) {
        let glow = CGGradient(colorsSpace: sRGB, colors: [NSColor.white.withAlphaComponent(alpha).cgColor,
                                                          NSColor.white.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        cg.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }

    func sunburst(_ center: CGPoint, rays: Int = 36, alpha: CGFloat = 0.05) {
        cg.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
        let step = CGFloat.pi * 2 / CGFloat(rays)
        for index in stride(from: 0, to: rays, by: 2) {
            let a = CGFloat(index) * step
            cg.move(to: center)
            cg.addLine(to: CGPoint(x: center.x + cos(a) * 3000, y: center.y + sin(a) * 3000))
            cg.addLine(to: CGPoint(x: center.x + cos(a + step) * 3000, y: center.y + sin(a + step) * 3000))
            cg.closePath()
        }
        cg.fillPath()
    }

    /// Draws an image centred on a point, rotated by degrees, with a drop shadow.
    func place(_ image: CGImage, center: CGPoint, width: CGFloat, angle: CGFloat = 0, shadow: CGFloat = 0.45) {
        let height = width * CGFloat(image.height) / CGFloat(image.width)
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: angle * .pi / 180)
        cg.scaleBy(x: 1, y: -1)
        cg.setShadow(offset: CGSize(width: 0, height: -24), blur: 50, color: NSColor.black.withAlphaComponent(shadow).cgColor)
        cg.interpolationQuality = .high
        cg.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        cg.restoreGState()
    }

    /// The headline, uppercased and as large as fits in `maxHeight`; returns its bottom edge.
    @discardableResult
    func headline(_ text: String, top: CGFloat, maxSize: CGFloat = 112, maxHeight: CGFloat, accent: NSColor = yellow,
                  color: NSColor = .white) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineHeightMultiple = 0.92
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: 6)
        shadow.shadowBlurRadius = 12
        func attributed(_ size: CGFloat) -> NSAttributedString {
            let result = NSMutableAttributedString()
            for (index, part) in text.uppercased(with: locale).components(separatedBy: "*").enumerated() {
                result.append(NSAttributedString(string: part, attributes: [
                    .font: roundedFont(size, .black), .foregroundColor: index % 2 == 1 ? accent : color,
                    .paragraphStyle: style, .shadow: shadow,
                ]))
            }
            return result
        }
        var size = maxSize
        var string = attributed(size)
        func bounds() -> CGRect { string.boundingRect(with: NSSize(width: W - 100, height: 2000), options: [.usesLineFragmentOrigin]) }
        // Shrink until it fits the height and no word breaks across lines.
        while size > 48 && (bounds().height > maxHeight || longestLineWidth(string) > W - 100) {
            size -= 4
            string = attributed(size)
        }
        let rect = bounds()
        string.draw(with: NSRect(x: 50, y: top, width: W - 100, height: rect.height + 10), options: [.usesLineFragmentOrigin])
        return top + rect.height
    }

    private func longestLineWidth(_ string: NSAttributedString) -> CGFloat {
        string.string.components(separatedBy: "\n").reduce(0) { widest, line in
            let range = (string.string as NSString).range(of: line)
            return max(widest, string.attributedSubstring(from: range).size().width)
        }
    }

    @discardableResult
    func subtitle(_ text: String, top: CGFloat, color: NSColor = NSColor.white.withAlphaComponent(0.88)) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let string = NSAttributedString(string: text, attributes: [.font: roundedFont(40, .semibold), .foregroundColor: color, .paragraphStyle: style])
        let rect = string.boundingRect(with: NSSize(width: W - 140, height: 400), options: [.usesLineFragmentOrigin])
        string.draw(with: NSRect(x: 70, y: top, width: W - 140, height: rect.height + 6), options: [.usesLineFragmentOrigin])
        return top + rect.height
    }

    func pill(_ text: String, center: CGPoint, font: NSFont, fill: NSColor, ink: NSColor, padding: CGFloat = 44, height: CGFloat = 96) {
        let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink])
        let size = string.size()
        let rect = CGRect(x: center.x - size.width / 2 - padding, y: center.y - height / 2, width: size.width + padding * 2, height: height)
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.3).cgColor)
        cg.addPath(CGPath(roundedRect: rect, cornerWidth: height / 2, cornerHeight: height / 2, transform: nil))
        cg.setFillColor(fill.cgColor)
        cg.fillPath()
        cg.restoreGState()
        string.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
    }

    /// The footer every ad shares: icon, name and tagline on the left, the CTA button on the right.
    func footer(_ text: Copy, ctaFill: NSColor = yellow, ctaInk: NSColor = hex(0x2A1460)) {
        let y = safeBottom - 60
        let iconRect = CGRect(x: 56, y: y - 56, width: 112, height: 112)
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 26, cornerHeight: 26, transform: nil))
        cg.setFillColor(NSColor.black.cgColor)
        cg.fillPath()
        cg.restoreGState()
        cg.saveGState()
        cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 26, cornerHeight: 26, transform: nil))
        cg.clip()
        cg.translateBy(x: 0, y: iconRect.midY * 2)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(icon, in: iconRect)
        cg.restoreGState()
        NSAttributedString(string: "Tixday", attributes: [.font: roundedFont(46, .heavy), .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: 190, y: y - 56))
        NSAttributedString(string: text.tagline, attributes: [.font: roundedFont(28, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.8)])
            .draw(at: NSPoint(x: 192, y: y + 6))
        let font = roundedFont(38, .heavy)
        let width = NSAttributedString(string: text.cta, attributes: [.font: font]).size().width + 88
        pill(text.cta, center: CGPoint(x: W - 56 - width / 2, y: y), font: font, fill: ctaFill, ink: ctaInk)
    }

    func save(_ url: URL) {
        NSGraphicsContext.restoreGraphicsState()
        let opaque = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                               bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        opaque.draw(cg.makeImage()!, in: CGRect(x: 0, y: 0, width: W, height: H))
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, opaque.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        CGImageDestinationFinalize(destination)
        print(url.path)
    }
}

// MARK: - Pieces from the app

struct Pieces {
    let widgetsScreen: CGImage
    let flight, train, concert, birthday, wedding, exam: CGImage
    let hero, stamped: CGImage

    init?(language: String) {
        let raw = rawDir.appending(path: language)
        guard let home = loadImage(raw.appending(path: "home.png")), let widgets = loadImage(raw.appending(path: "widgets.png")),
              let used = loadImage(raw.appending(path: "used.png")) else { return nil }
        widgetsScreen = widgets
        flight = cut(widgets, CGRect(x: 80, y: 398, width: 1160, height: 538), radius: 72)
        train = cut(widgets, CGRect(x: 80, y: 1636, width: 1160, height: 538), radius: 72)
        concert = cut(widgets, CGRect(x: 80, y: 1018, width: 540, height: 540), radius: 72)
        birthday = cut(widgets, CGRect(x: 700, y: 1018, width: 540, height: 540), radius: 72)
        exam = cut(widgets, CGRect(x: 80, y: 2258, width: 540, height: 540), radius: 72)
        wedding = cut(widgets, CGRect(x: 700, y: 2258, width: 540, height: 540), radius: 72)
        hero = cut(home, CGRect(x: 60, y: 441, width: 1197, height: 884), radius: 84)
        // Just the poster, with its ADMITTED stamp.
        stamped = cut(used, CGRect(x: 62, y: 372, width: 1196, height: 656), radius: 84)
    }
}

/// A plain, grey note: the "before" in the before / after ad.
func plainNote(_ text: Copy, size: CGFloat) -> CGImage {
    let cg = bitmap(Int(size), Int(size))
    cg.translateBy(x: 0, y: size)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: size * 0.13, cornerHeight: size * 0.13, transform: nil))
    cg.setFillColor(hex(0xF2F2F4).cgColor)
    cg.fillPath()
    // Ruled lines, like a notes app.
    cg.setStrokeColor(hex(0xD8D8DE).cgColor)
    cg.setLineWidth(2)
    var y = size * 0.3
    while y < size - 30 {
        cg.move(to: CGPoint(x: 30, y: y))
        cg.addLine(to: CGPoint(x: size - 30, y: y))
        y += size * 0.12
    }
    cg.strokePath()
    let ink = hex(0x3A3A40)
    NSAttributedString(string: text.plainNote, attributes: [.font: NSFont.systemFont(ofSize: size * 0.075, weight: .regular), .foregroundColor: ink])
        .draw(at: NSPoint(x: size * 0.08, y: size * 0.32))
    NSAttributedString(string: text.plainDays, attributes: [.font: NSFont.systemFont(ofSize: size * 0.06, weight: .regular), .foregroundColor: ink.withAlphaComponent(0.6)])
        .draw(at: NSPoint(x: size * 0.08, y: size * 0.44))
    NSGraphicsContext.restoreGraphicsState()
    return cg.makeImage()!
}

// MARK: - The ads

/// The art area between the headline block and the footer.
func artArea(_ c: Canvas, below top: CGFloat) -> CGRect {
    CGRect(x: 0, y: top + 30, width: W, height: c.safeBottom - 150 - top - 30)
}

let ads: [(name: String, draw: (Canvas, Copy, Pieces) -> Void)] = [
    ("widgets", { c, text, p in
        c.gradient([hex(0x2A1460), hex(0x5A2DBE), hex(0xB8346C)], locations: [0, 0.55, 1])
        c.sunburst(CGPoint(x: W / 2, y: c.H * 0.7))
        c.glow(CGPoint(x: W / 2, y: c.H * 0.62), radius: 600)
        let h = c.headline(text.headlines["widgets"]!.0, top: c.safeTop, maxHeight: 250)
        let s = c.subtitle(text.headlines["widgets"]!.1!, top: h + 14)
        let area = artArea(c, below: s)
        // The phone is cut off by the footer area, showing the top of the widget screen.
        let screenWidth = min(620, area.height * 0.95 / (2868 / 1320))
        let device = phone(p.widgetsScreen, screenWidth: max(screenWidth, 520))
        let width = CGFloat(device.width)
        let height = CGFloat(device.height)
        c.cg.saveGState()
        c.cg.clip(to: CGRect(x: 0, y: 0, width: W, height: c.safeBottom - 150))
        c.place(device, center: CGPoint(x: W / 2, y: area.minY + 20 + height / 2), width: width, shadow: 0.5)
        c.cg.restoreGState()
        // Fade the cut edge into the footer.
        let fade = CGGradient(colorsSpace: sRGB, colors: [hex(0xB8346C, 0).cgColor, hex(0xB0326B).cgColor] as CFArray, locations: [0, 1])!
        c.cg.drawLinearGradient(fade, start: CGPoint(x: 0, y: c.safeBottom - 330), end: CGPoint(x: 0, y: c.safeBottom - 150),
                                options: [.drawsAfterEndLocation])
        c.footer(text)
    }),
    ("birthday", { c, text, p in
        c.gradient([hex(0x7A2E12), hex(0xD9662B), hex(0xF2A93B)], locations: [0, 0.6, 1])
        c.sunburst(CGPoint(x: W / 2, y: c.H * 0.55), alpha: 0.06)
        c.glow(CGPoint(x: W / 2, y: c.H * 0.52), radius: 520)
        let h = c.headline(text.headlines["birthday"]!.0, top: c.safeTop, maxHeight: 250, accent: hex(0xFFF1B8))
        let s = c.subtitle(text.headlines["birthday"]!.1!, top: h + 14)
        let area = artArea(c, below: s)
        let cardWidth = min(900, (area.height - 140) / 884 * 1197)
        let cardHeight = cardWidth * 884 / 1197
        let cardCenter = CGPoint(x: W / 2, y: area.midY - 50)
        c.place(p.hero, center: cardCenter, width: cardWidth, angle: -3)
        c.pill("↻  " + text.repeats, center: CGPoint(x: W / 2, y: cardCenter.y + cardHeight / 2 + 50),
               font: roundedFont(40, .heavy), fill: .white, ink: hex(0xB4471C), height: 92)
        c.footer(text, ctaFill: .white, ctaInk: hex(0xB4471C))
    }),
    ("before", { c, text, p in
        c.gradient([hex(0x141226), hex(0x2B1F4E)])
        c.glow(CGPoint(x: W * 0.74, y: c.H * 0.5), radius: 520, alpha: 0.18)
        let h = c.headline(text.headlines["before"]!.0, top: c.safeTop, maxHeight: 240)
        let area = artArea(c, below: h + 20)
        let size: CGFloat = min(400, area.height - 160)
        let y = area.midY + 30
        let labelFont = roundedFont(34, .heavy)
        c.pill(text.before, center: CGPoint(x: W * 0.27, y: y - size / 2 - 70), font: labelFont, fill: NSColor.white.withAlphaComponent(0.14),
               ink: NSColor.white.withAlphaComponent(0.75), padding: 30, height: 70)
        c.pill(text.after, center: CGPoint(x: W * 0.73, y: y - size / 2 - 70), font: labelFont, fill: yellow, ink: hex(0x2A1460),
               padding: 30, height: 70)
        c.place(plainNote(text, size: size * 2), center: CGPoint(x: W * 0.27, y: y), width: size, angle: -2, shadow: 0.3)
        c.place(p.wedding, center: CGPoint(x: W * 0.73, y: y), width: size * 1.08, angle: 3, shadow: 0.55)
        // The arrow, in a badge over the gap.
        c.cg.saveGState()
        c.cg.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.4).cgColor)
        c.cg.setFillColor(yellow.cgColor)
        c.cg.fillEllipse(in: CGRect(x: W / 2 - 50, y: y - 50, width: 100, height: 100))
        c.cg.restoreGState()
        let arrow = NSAttributedString(string: "→", attributes: [.font: roundedFont(64, .black), .foregroundColor: hex(0x2A1460)])
        arrow.draw(at: NSPoint(x: W / 2 - arrow.size().width / 2, y: y - arrow.size().height / 2 - 4))
        c.footer(text)
    }),
    ("question", { c, text, p in
        c.gradient([hex(0x0E3B3A), hex(0x17605A), hex(0x2E8C6E)])
        c.sunburst(CGPoint(x: W / 2, y: c.H + 200), alpha: 0.06)
        c.glow(CGPoint(x: W / 2, y: c.H * 0.6), radius: 560, alpha: 0.2)
        let h = c.headline(text.headlines["question"]!.0, top: c.safeTop, maxHeight: c.H > 1500 ? 380 : 330, accent: yellow)
        let s = c.subtitle(text.headlines["question"]!.1!, top: h + 14)
        let area = artArea(c, below: s)
        let y = area.midY
        let unit = min(1, area.height / 560)
        c.place(p.exam, center: CGPoint(x: W / 2 - 370 * unit, y: y - 30 * unit), width: 250 * unit, angle: -14)
        c.place(p.wedding, center: CGPoint(x: W / 2 + 370 * unit, y: y - 30 * unit), width: 250 * unit, angle: 14)
        c.place(p.concert, center: CGPoint(x: W / 2 - 190 * unit, y: y - 90 * unit), width: 290 * unit, angle: -7)
        c.place(p.birthday, center: CGPoint(x: W / 2 + 190 * unit, y: y - 90 * unit), width: 290 * unit, angle: 7)
        c.place(p.flight, center: CGPoint(x: W / 2, y: y + 140 * unit), width: 640 * unit)
        c.footer(text)
    }),
    ("trip", { c, text, p in
        c.gradient([hex(0x0A2350), hex(0x1F4F9A), hex(0xE88A5A)], locations: [0, 0.55, 1])
        c.glow(CGPoint(x: W * 0.7, y: c.H * 0.45), radius: 520, alpha: 0.25)
        let h = c.headline(text.headlines["trip"]!.0, top: c.safeTop, maxHeight: c.H > 1500 ? 380 : 300)
        let s = c.subtitle(text.headlines["trip"]!.1!, top: h + 14)
        let area = artArea(c, below: s)
        let width = min(860, area.height * 0.85 / (538.0 / 1160) / 1.7)
        let height = width * 538 / 1160
        c.place(p.train, center: CGPoint(x: W / 2 + 70, y: area.midY + height * 0.42), width: width * 0.9, angle: 4, shadow: 0.4)
        c.place(p.flight, center: CGPoint(x: W / 2 - 40, y: area.midY - height * 0.38), width: width, angle: -4, shadow: 0.55)
        c.footer(text)
    }),
    ("ticket", { c, text, p in
        c.gradient([hex(0x1B0F3A), hex(0x40207A), hex(0x8E2D6A)], locations: [0, 0.6, 1])
        c.sunburst(CGPoint(x: W / 2, y: c.H * 0.6))
        c.glow(CGPoint(x: W / 2, y: c.H * 0.58), radius: 560)
        let h = c.headline(text.headlines["ticket"]!.0, top: c.safeTop, maxSize: 124, maxHeight: 260)
        let s = c.subtitle(text.headlines["ticket"]!.1!, top: h + 14)
        let area = artArea(c, below: s)
        let width = min(860, area.height * 0.8 / (656.0 / 1196))
        c.place(p.birthday, center: CGPoint(x: W / 2 + width * 0.36, y: area.midY - width * 0.2), width: width * 0.4, angle: 12, shadow: 0.4)
        c.place(p.stamped, center: CGPoint(x: W / 2 - 20, y: area.midY + 10), width: width, angle: -4, shadow: 0.55)
        c.footer(text)
    }),
]

for language in copy.keys.sorted() {
    guard let pieces = Pieces(language: language), let text = copy[language] else {
        print("skipping \(language)")
        continue
    }
    let folder = outDir.appending(path: language)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for (index, ad) in ads.enumerated() {
        for (format, height) in [("4x5", CGFloat(1350)), ("9x16", CGFloat(1920))] {
            let canvas = Canvas(height: height, locale: Locale(identifier: language))
            ad.draw(canvas, text, pieces)
            canvas.save(folder.appending(path: "\(index + 1)-\(ad.name)-\(format).jpg"))
        }
    }
}
