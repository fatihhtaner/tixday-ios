// Renders carousels (slideshows) for Instagram and TikTok photo mode: six 1080×1350 slides each,
// hook on the first, one message per slide (12 words at most), the app on slide 2 or 3, CTA on the last.
//   dates        – dates worth counting down to (trip, concert, birthday, Christmas)
//   how-to       – a countdown on your Home Screen in 3 steps
//   before-after – countdowns before and after Tixday
// No review or rating slides until the App Store has real ones.
//
// Usage: swift tools/make_carousels.swift <raw-dir> <out-dir>
//   <raw-dir>/<lang>/{widgets,birthday,editor}.png come from tools/capture_store_screens.sh (en and tr).
//   Writes <out-dir>/<lang>/<carousel>-<n>.jpg.
// Drawing helpers are the same as tools/make_static_ads.swift.
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make_carousels.swift <raw-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
let W: CGFloat = 1080, H: CGFloat = 1350

/// Footer words; every other text is in `slides` below.
struct Copy {
    let tagline, cta, swipe: String
}
let copy: [String: Copy] = [
    "en": Copy(tagline: "Countdown Widgets", cta: "Free · Link in bio", swipe: "Swipe →"),
    "tr": Copy(tagline: "Geri Sayım Widget'ları", cta: "Ücretsiz · Link bio'da", swipe: "Kaydır →"),
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
    let cg: CGContext
    let locale: Locale

    init(height: CGFloat, locale: Locale) {
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
    let everyYear, kinds, fields: CGImage

    init?(language: String) {
        let raw = rawDir.appending(path: language)
        guard let widgets = loadImage(raw.appending(path: "widgets.png")), let detail = loadImage(raw.appending(path: "birthday.png")),
              let editor = loadImage(raw.appending(path: "editor.png")) else { return nil }
        widgetsScreen = widgets
        flight = cut(widgets, CGRect(x: 80, y: 398, width: 1160, height: 538), radius: 72)
        train = cut(widgets, CGRect(x: 80, y: 1636, width: 1160, height: 538), radius: 72)
        concert = cut(widgets, CGRect(x: 80, y: 1018, width: 540, height: 540), radius: 72)
        birthday = cut(widgets, CGRect(x: 700, y: 1018, width: 540, height: 540), radius: 72)
        exam = cut(widgets, CGRect(x: 80, y: 2258, width: 540, height: 540), radius: 72)
        wedding = cut(widgets, CGRect(x: 700, y: 2258, width: 540, height: 540), radius: 72)
        // The birthday's "Every year" card, the editor's ticket kinds and its title / date fields.
        everyYear = cut(detail, CGRect(x: 62, y: 1325, width: 1196, height: 368), radius: 64)
        kinds = cut(editor, CGRect(x: 30, y: 1390, width: 1290, height: 370), radius: 0)
        fields = cut(editor, CGRect(x: 62, y: 2150, width: 1196, height: 680), radius: 64)
    }
}

/// A plain list, the way most people keep their dates: the "before" picture.
func plainList(_ lines: [String], width: CGFloat) -> CGImage {
    let rowHeight: CGFloat = 92
    let height = rowHeight * CGFloat(lines.count) + 90
    let cg = bitmap(Int(width), Int(height))
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    cg.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerWidth: 48, cornerHeight: 48, transform: nil))
    cg.setFillColor(hex(0xF2F2F4).cgColor)
    cg.fillPath()
    cg.setStrokeColor(hex(0xD8D8DE).cgColor)
    cg.setLineWidth(2)
    for (index, line) in lines.enumerated() {
        let y = 45 + rowHeight * CGFloat(index)
        NSAttributedString(string: line, attributes: [.font: NSFont.systemFont(ofSize: 40), .foregroundColor: hex(0x3A3A40)])
            .draw(at: NSPoint(x: 44, y: y + 20))
        if index < lines.count - 1 {
            cg.move(to: CGPoint(x: 44, y: y + rowHeight))
            cg.addLine(to: CGPoint(x: width - 44, y: y + rowHeight))
        }
    }
    cg.strokePath()
    NSGraphicsContext.restoreGraphicsState()
    return cg.makeImage()!
}

/// A Lock Screen style notification from Tixday.
func notification(title: String, body: String, width: CGFloat) -> CGImage {
    let height: CGFloat = 190
    let cg = bitmap(Int(width), Int(height))
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    cg.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerWidth: 54, cornerHeight: 54, transform: nil))
    cg.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    cg.fillPath()
    cg.saveGState()
    let iconRect = CGRect(x: 34, y: 43, width: 104, height: 104)
    cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 24, cornerHeight: 24, transform: nil))
    cg.clip()
    cg.translateBy(x: 0, y: iconRect.midY * 2)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(icon, in: iconRect)
    cg.restoreGState()
    let ink = hex(0x16161A)
    NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .bold), .foregroundColor: ink])
        .draw(at: NSPoint(x: 166, y: 42))
    NSAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 38), .foregroundColor: ink.withAlphaComponent(0.8)])
        .draw(at: NSPoint(x: 166, y: 98))
    NSGraphicsContext.restoreGraphicsState()
    return cg.makeImage()!
}

// MARK: - Slides

/// Every slide's frame: background, the slide number, the headline block; returns where the art can start.
struct Look { let colors: [NSColor]; let accent: NSColor; let ink: NSColor }

extension Canvas {
    /// Background, page number top right and a small Tixday mark top left.
    func frame(_ look: Look, page: Int, of pages: Int) {
        gradient(look.colors)
        sunburst(CGPoint(x: W / 2, y: H + 300), alpha: 0.05)
        glow(CGPoint(x: W / 2, y: H * 0.62), radius: 560, alpha: 0.18)
        let iconRect = CGRect(x: 56, y: 52, width: 64, height: 64)
        cg.saveGState()
        cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 15, cornerHeight: 15, transform: nil))
        cg.clip()
        cg.translateBy(x: 0, y: iconRect.midY * 2)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(icon, in: iconRect)
        cg.restoreGState()
        NSAttributedString(string: "Tixday", attributes: [.font: roundedFont(34, .heavy), .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: 136, y: 62))
        let number = NSAttributedString(string: "\(page)/\(pages)", attributes: [.font: roundedFont(30, .bold), .foregroundColor: NSColor.white.withAlphaComponent(0.85)])
        pill("\(page)/\(pages)", center: CGPoint(x: W - 56 - number.size().width / 2 - 26, y: 84), font: roundedFont(30, .bold),
             fill: NSColor.black.withAlphaComponent(0.22), ink: NSColor.white.withAlphaComponent(0.9), padding: 26, height: 60)
    }

    /// A step badge ("1", "2", "★") left of nothing: centred above the headline.
    func badge(_ text: String, center: CGPoint, look: Look) {
        cg.setFillColor(look.accent.cgColor)
        cg.fillEllipse(in: CGRect(x: center.x - 50, y: center.y - 50, width: 100, height: 100))
        let string = NSAttributedString(string: text, attributes: [.font: roundedFont(56, .black), .foregroundColor: look.ink])
        string.draw(at: NSPoint(x: center.x - string.size().width / 2, y: center.y - string.size().height / 2))
    }

    /// The last slide of every carousel: icon, name and the CTA.
    func ctaSlide(_ headline: String, _ text: Copy, look: Look, pieces p: Pieces) {
        let h = self.headline(headline, top: 190, maxSize: 104, maxHeight: 260, accent: look.accent)
        place(p.train, center: CGPoint(x: W / 2 - 150, y: h + 170), width: 480, angle: -8, shadow: 0.4)
        place(p.flight, center: CGPoint(x: W / 2 + 150, y: h + 250), width: 520, angle: 6, shadow: 0.5)
        let iconRect = CGRect(x: W / 2 - 90, y: H - 520, width: 180, height: 180)
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: NSColor.black.withAlphaComponent(0.4).cgColor)
        cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 42, cornerHeight: 42, transform: nil))
        cg.setFillColor(NSColor.black.cgColor)
        cg.fillPath()
        cg.restoreGState()
        cg.saveGState()
        cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 42, cornerHeight: 42, transform: nil))
        cg.clip()
        cg.translateBy(x: 0, y: iconRect.midY * 2)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(icon, in: iconRect)
        cg.restoreGState()
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        NSAttributedString(string: "Tixday", attributes: [.font: roundedFont(64, .black), .foregroundColor: NSColor.white, .paragraphStyle: style])
            .draw(with: NSRect(x: 0, y: H - 320, width: W, height: 80), options: [.usesLineFragmentOrigin])
        NSAttributedString(string: text.tagline, attributes: [.font: roundedFont(34, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.8), .paragraphStyle: style])
            .draw(with: NSRect(x: 0, y: H - 240, width: W, height: 50), options: [.usesLineFragmentOrigin])
        pill(text.cta, center: CGPoint(x: W / 2, y: H - 120), font: roundedFont(42, .heavy), fill: look.accent, ink: look.ink, padding: 56, height: 104)
    }

    func swipeHint(_ text: Copy) {
        pill(text.swipe, center: CGPoint(x: W / 2, y: H - 100), font: roundedFont(36, .heavy), fill: NSColor.white.withAlphaComponent(0.16),
             ink: .white, padding: 40, height: 84)
    }
}

typealias Slide = (Canvas, Pieces) -> Void

/// The text for one carousel in one language: per slide a headline and an optional subtitle.
struct Carousel {
    let name: String
    let look: Look
    let slides: (String, Copy) -> [Slide]
}

func text(_ language: String, _ en: String, _ tr: String) -> String { language == "tr" ? tr : en }

let violet = Look(colors: [hex(0x2A1460), hex(0x5A2DBE), hex(0xB8346C)], accent: hex(0xFFD84D), ink: hex(0x2A1460))
let pine = Look(colors: [hex(0x0E3B3A), hex(0x17605A), hex(0x2E8C6E)], accent: hex(0xFFD84D), ink: hex(0x0E3B3A))
let night = Look(colors: [hex(0x141226), hex(0x2B1F4E), hex(0x4A2B6E)], accent: hex(0xFFD84D), ink: hex(0x2A1460))

let carousels: [Carousel] = [
    Carousel(name: "dates", look: violet) { l, t in
        let look = violet
        /// A numbered date: badge, headline, subtitle, the ticket.
        func date(_ n: String, _ title: String, _ sub: String, _ art: @escaping (Pieces) -> CGImage, wide: Bool) -> Slide {
            { c, p in
                c.badge(n, center: CGPoint(x: W / 2, y: 230), look: look)
                let h = c.headline(title, top: 310, maxSize: 96, maxHeight: 200, accent: look.accent)
                let s = c.subtitle(sub, top: h + 16)
                let width: CGFloat = wide ? 900 : 620
                let image = art(p)
                let height = width * CGFloat(image.height) / CGFloat(image.width)
                c.place(image, center: CGPoint(x: W / 2, y: max(s + 60 + height / 2, (s + H) / 2 + 10)), width: width, angle: wide ? -3 : 3)
            }
        }
        return [
            { c, p in
                let h = c.headline(text(l, "Dates worth\n*counting down* to", "Geri saymaya\n*değer* tarihler"), top: 190, maxSize: 120, maxHeight: 300, accent: look.accent)
                c.subtitle(text(l, "Save this for later 📌", "Sonra bakmak için kaydet 📌"), top: h + 16)
                let y = (h + H) / 2 + 20
                c.place(p.exam, center: CGPoint(x: W / 2 - 330, y: y - 20), width: 280, angle: -13)
                c.place(p.wedding, center: CGPoint(x: W / 2 + 330, y: y - 20), width: 280, angle: 13)
                c.place(p.concert, center: CGPoint(x: W / 2 - 170, y: y - 70), width: 320, angle: -6)
                c.place(p.birthday, center: CGPoint(x: W / 2 + 170, y: y - 70), width: 320, angle: 6)
                c.place(p.flight, center: CGPoint(x: W / 2, y: y + 120), width: 640)
                c.swipeHint(t)
            },
            date("1", text(l, "Your next *trip*", "Bir sonraki *tatilin*"),
                 text(l, "Watching the number drop is half the fun.", "Sayının düştüğünü izlemek işin yarısı."), { $0.flight }, wide: true),
            date("2", text(l, "That *concert*", "O *konser*"),
                 text(l, "Every day a little closer to the front row.", "Her gün sahneye biraz daha yakın."), { $0.concert }, wide: false),
            date("3", text(l, "Their *birthday*", "Onun *doğum günü*"),
                 text(l, "Set it once. It comes back every year.", "Bir kez kur, her yıl geri gelir."), { $0.birthday }, wide: false),
            date("4", text(l, "*Christmas*", "*Yılbaşı*"),
                 text(l, "A train ticket home, every December.", "Her aralık eve bir tren bileti."), { $0.train }, wide: true),
            { c, p in c.ctaSlide(text(l, "Put yours on\nyour *Home Screen*", "Seninkileri\n*ana ekranına* koy"), t, look: look, pieces: p) },
        ]
    },
    Carousel(name: "how-to", look: pine) { l, t in
        let look = pine
        func step(_ n: String, _ title: String, _ sub: String, _ draw: @escaping (Canvas, Pieces, CGFloat) -> Void) -> Slide {
            { c, p in
                c.badge(n, center: CGPoint(x: W / 2, y: 230), look: look)
                let h = c.headline(title, top: 310, maxSize: 92, maxHeight: 200, accent: look.accent)
                let s = c.subtitle(sub, top: h + 16)
                draw(c, p, s)
            }
        }
        return [
            { c, p in
                let h = c.headline(text(l, "A countdown on\nyour Home Screen\nin *3 steps*", "Ana ekranına\ngeri sayım:\n*3 adım*"),
                                   top: 190, maxSize: 112, maxHeight: 380, accent: look.accent)
                let device = phone(p.widgetsScreen, screenWidth: 520)
                c.cg.saveGState()
                c.cg.clip(to: CGRect(x: 0, y: 0, width: W, height: H - 170))
                c.place(device, center: CGPoint(x: W / 2, y: h + 70 + CGFloat(device.height) / 2), width: CGFloat(device.width), shadow: 0.5)
                c.cg.restoreGState()
                c.swipeHint(t)
            },
            step("1", text(l, "Tap *New ticket*", "*Yeni bilet*'e dokun"),
                 text(l, "Then pick a kind: trip, concert, birthday…", "Sonra türünü seç: tatil, konser, doğum günü…")) { c, p, s in
                c.place(p.kinds, center: CGPoint(x: W / 2, y: (s + H) / 2 + 20), width: W + 40, shadow: 0.3)
            },
            step("2", text(l, "Name it, pick *the date*", "Adını yaz, *tarihi* seç"),
                 text(l, "It turns into a ticket right away.", "Hemen bir bilete dönüşür.")) { c, p, s in
                c.place(p.fields, center: CGPoint(x: W / 2, y: (s + H) / 2 + 10), width: 880)
            },
            step("3", text(l, "Add the *widget*", "*Widget*'ı ekle"),
                 text(l, "Hold the Home Screen, tap +, choose Tixday.", "Ana ekrana basılı tut, +'ya dokun, Tixday'i seç.")) { c, p, s in
                let y = (s + H) / 2 + 10
                c.place(p.concert, center: CGPoint(x: W / 2 - 200, y: y), width: 340, angle: -5)
                c.place(p.birthday, center: CGPoint(x: W / 2 + 200, y: y), width: 340, angle: 5)
            },
            { c, p in
                let h = c.headline(text(l, "Done. It counts\ndown *by itself*", "Bitti. Kendi\nkendine *geri sayar*"), top: 190, maxSize: 104, maxHeight: 260, accent: look.accent)
                let s = c.subtitle(text(l, "Every time you unlock your phone.", "Telefonunu her açtığında."), top: h + 16)
                let device = phone(p.widgetsScreen, screenWidth: 500)
                c.cg.saveGState()
                c.cg.clip(to: CGRect(x: 0, y: 0, width: W, height: H))
                c.place(device, center: CGPoint(x: W / 2, y: s + 60 + CGFloat(device.height) / 2), width: CGFloat(device.width), shadow: 0.5)
                c.cg.restoreGState()
            },
            { c, p in c.ctaSlide(text(l, "Make your\n*first ticket*", "İlk biletini\n*oluştur*"), t, look: look, pieces: p) },
        ]
    },
    Carousel(name: "before-after", look: night) { l, t in
        let look = night
        let beforeLabel = text(l, "BEFORE", "ÖNCE"), afterLabel = text(l, "AFTER", "SONRA")
        /// A before and an after on one slide, stacked.
        func pair(_ title: String, before: @escaping (Pieces) -> CGImage, beforeWidth: CGFloat,
                  after: @escaping (Pieces) -> CGImage, afterWidth: CGFloat) -> Slide {
            { c, p in
                let h = c.headline(title, top: 170, maxSize: 92, maxHeight: 200, accent: look.accent)
                let top = h + 40, bottom = H - 60
                let half = (bottom - top) / 2
                for (index, (label, art, width)) in [(beforeLabel, before, beforeWidth), (afterLabel, after, afterWidth)].enumerated() {
                    let image = art(p)
                    let y = top + half * CGFloat(index) + half / 2 + 20
                    let height = min(half - 70, width * CGFloat(image.height) / CGFloat(image.width))
                    let w = height * CGFloat(image.width) / CGFloat(image.height)
                    c.place(image, center: CGPoint(x: W / 2 + 60, y: y), width: w, shadow: index == 0 ? 0.25 : 0.5)
                    c.pill(label, center: CGPoint(x: 130, y: y - height / 2 + 6), font: roundedFont(30, .heavy),
                           fill: index == 0 ? NSColor.white.withAlphaComponent(0.85) : look.accent,
                           ink: index == 0 ? hex(0x3A3A40) : look.ink, padding: 24, height: 60)
                }
            }
        }
        let notes = [text(l, "Tokyo trip – Jan 21", "Tokyo tatili – 21 Ocak"), text(l, "Concert – Nov 17", "Konser – 17 Kasım"),
                     text(l, "Her birthday – Dec 15?", "Doğum günü – 15 Aralık?"), text(l, "Wedding – Apr 4", "Düğün – 4 Nisan")]
        return [
            { c, p in
                let h = c.headline(text(l, "Your countdowns:\n*before vs after*", "Geri sayımların:\n*önce ve sonra*"), top: 190, maxSize: 110, maxHeight: 280, accent: look.accent)
                let y = (h + H) / 2 - 10
                c.place(plainList(Array(notes.prefix(3)), width: 620), center: CGPoint(x: W / 2 - 170, y: y - 30), width: 520, angle: -5, shadow: 0.3)
                c.place(p.flight, center: CGPoint(x: W / 2 + 140, y: y + 90), width: 620, angle: 4)
                c.swipeHint(t)
            },
            pair(text(l, "Dates *buried* in notes", "Notlarda *kaybolan* tarihler"),
                 before: { _ in plainList(notes, width: 820) }, beforeWidth: 760,
                 after: { $0.flight }, afterWidth: 820),
            pair(text(l, "Doing the *math* yourself", "Günleri *kendin* saymak"),
                 before: { _ in plainList([text(l, "Jan 21 – today = ??", "21 Ocak – bugün = ??")], width: 820) }, beforeWidth: 760,
                 after: { $0.concert }, afterWidth: 440),
            pair(text(l, "Re-adding *birthdays*", "Doğum günlerini *yeniden eklemek*"),
                 before: { _ in plainList([text(l, "Add her birthday again", "Doğum gününü yine ekle"), text(l, "…every single year", "…her yıl, yeniden")], width: 820) },
                 beforeWidth: 760, after: { $0.everyYear }, afterWidth: 860),
            pair(text(l, "*Forgetting* the day", "O günü *unutmak*"),
                 before: { _ in plainList([text(l, "Wait, that was today?!", "Dur, bugün müydü?!")], width: 820) }, beforeWidth: 760,
                 after: { _ in notification(title: "Tixday", body: text(l, "Tomorrow's the day!", "Yarın o gün!"), width: 860) }, afterWidth: 860),
            { c, p in c.ctaSlide(text(l, "Upgrade your\n*countdowns*", "Geri sayımlarını\n*yükselt*"), t, look: look, pieces: p) },
        ]
    },
]

for language in copy.keys.sorted() {
    guard let pieces = Pieces(language: language), let words = copy[language] else {
        print("skipping \(language)")
        continue
    }
    let folder = outDir.appending(path: language)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for carousel in carousels {
        let slides = carousel.slides(language, words)
        for (index, slide) in slides.enumerated() {
            let canvas = Canvas(height: H, locale: Locale(identifier: language))
            canvas.frame(carousel.look, page: index + 1, of: slides.count)
            slide(canvas, pieces)
            canvas.save(folder.appending(path: "\(carousel.name)-\(index + 1).jpg"))
        }
    }
}
