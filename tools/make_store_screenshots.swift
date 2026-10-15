// Renders the App Store screenshots. Every slide has its own layout (not one template in five colours):
//   1 home      – sunburst, headline on top, upright phone, the hero ticket popping out
//   2 widgets   – no phone: the widgets as a tilted collage over soft blobs
//   3 birthday  – phone on top, headline at the bottom, the "every year" card popping out
//   4 editor    – left-aligned headline, phone leaning off the right edge, ticket kinds fanned on the left
//   5 used      – no phone: the stamped ticket, a big ADMITTED sticker and two reminder notifications
// Headlines are uppercased; *word* is drawn in the accent colour. Output is 1320×2868 JPEG (6.9-inch).
//
// Usage: swift tools/make_store_screenshots.swift <raw-dir> <out-dir> [store-locale …]
//   <raw-dir>/<lang>/{home,widgets,birthday,editor,used}.png come from tools/capture_store_screens.sh;
//   texts from docs/app-store/screenshot-texts.json, notification and stamp words from the app's string catalog;
//   writes <out-dir>/<store-locale>/1_home.jpg …, the layout fastlane deliver uploads (fastlane/screenshots).
// CoreText draws every script, including Arabic (right to left) and Japanese, Korean and Chinese.
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: make_store_screenshots.swift <raw-dir> <out-dir> [store-locale …]\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let onlyLocales = Set(args.dropFirst(3))
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
/// Text keys are App Store locales; raw captures and the string catalog use the app's language codes.
let appLanguage = ["en": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "ar-SA": "ar"]
let storeLocale = ["en": "en-US"]

let W: CGFloat = 1320, H: CGFloat = 2868
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Basics (all coordinates from the top left)

func hex(_ value: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255, alpha: alpha)
}

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

/// A slide being drawn: a flipped context, so y grows downwards like a screen.
final class Canvas {
    let cg = bitmap(Int(W), Int(H))
    let locale: Locale

    init(locale: Locale) {
        self.locale = locale
        cg.translateBy(x: 0, y: H)
        cg.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    }

    func gradient(_ top: NSColor, _ bottom: NSColor) {
        let gradient = CGGradient(colorsSpace: sRGB, colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
        cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    }

    func glow(_ center: CGPoint, radius: CGFloat, alpha: CGFloat = 0.22) {
        let glow = CGGradient(colorsSpace: sRGB, colors: [NSColor.white.withAlphaComponent(alpha).cgColor,
                                                          NSColor.white.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        cg.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }

    /// Rays fanning out from a point, like an old poster.
    func sunburst(_ center: CGPoint, rays: Int, alpha: CGFloat) {
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

    func blob(_ rect: CGRect, color: NSColor) {
        cg.setFillColor(color.cgColor)
        cg.fillEllipse(in: rect)
    }

    func sparkle(_ center: CGPoint, size: CGFloat, color: NSColor) {
        let inner = size * 0.18
        cg.move(to: CGPoint(x: center.x, y: center.y - size))
        cg.addQuadCurve(to: CGPoint(x: center.x + size, y: center.y), control: CGPoint(x: center.x + inner, y: center.y - inner))
        cg.addQuadCurve(to: CGPoint(x: center.x, y: center.y + size), control: CGPoint(x: center.x + inner, y: center.y + inner))
        cg.addQuadCurve(to: CGPoint(x: center.x - size, y: center.y), control: CGPoint(x: center.x - inner, y: center.y + inner))
        cg.addQuadCurve(to: CGPoint(x: center.x, y: center.y - size), control: CGPoint(x: center.x - inner, y: center.y - inner))
        cg.setFillColor(color.cgColor)
        cg.fillPath()
    }

    /// A tear-off ticket stub, for confetti.
    func stub(_ center: CGPoint, width: CGFloat, angle: CGFloat, color: NSColor) {
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: angle * .pi / 180)
        let rect = CGRect(x: -width / 2, y: -width * 0.28, width: width, height: width * 0.56)
        cg.addPath(CGPath(roundedRect: rect, cornerWidth: width * 0.1, cornerHeight: width * 0.1, transform: nil))
        cg.setFillColor(color.cgColor)
        cg.fillPath()
        cg.setStrokeColor(NSColor.black.withAlphaComponent(0.18).cgColor)
        cg.setLineWidth(width * 0.04)
        cg.setLineDash(phase: 0, lengths: [width * 0.07, width * 0.06])
        cg.move(to: CGPoint(x: width * 0.18, y: -width * 0.24))
        cg.addLine(to: CGPoint(x: width * 0.18, y: width * 0.24))
        cg.strokePath()
        cg.restoreGState()
    }

    /// Draws an image centred on `center`, rotated by `angle` degrees (clockwise), with a drop shadow.
    func place(_ image: CGImage, center: CGPoint, width: CGFloat, angle: CGFloat = 0, shadow: CGFloat = 70) {
        let height = width * CGFloat(image.height) / CGFloat(image.width)
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: angle * .pi / 180)
        cg.scaleBy(x: 1, y: -1)
        if shadow > 0 {
            cg.setShadow(offset: CGSize(width: 0, height: -shadow * 0.45), blur: shadow, color: NSColor.black.withAlphaComponent(0.42).cgColor)
        }
        cg.interpolationQuality = .high
        cg.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        cg.restoreGState()
    }

    /// Headline: uppercase, black rounded type with a hard shadow, `*accent*` words in colour.
    @discardableResult
    func headline(_ text: String, top: CGFloat, accent: NSColor, align: NSTextAlignment = .center,
                  x: CGFloat = 40, width: CGFloat = W - 80, maxSize: CGFloat = 138) -> CGFloat {
        let upper = text.uppercased(with: locale)
        var size = maxSize
        while size > 70 && upper.replacingOccurrences(of: "*", with: "").split(separator: "\n").contains(where: {
            NSAttributedString(string: String($0), attributes: [.font: roundedFont(size, .black)]).size().width > width - 20
        }) { size -= 4 }
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineHeightMultiple = 0.9
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowOffset = NSSize(width: 0, height: 7)
        let string = NSMutableAttributedString()
        for (index, part) in upper.components(separatedBy: "*").enumerated() {
            string.append(NSAttributedString(string: part, attributes: [
                .font: roundedFont(size, .black), .foregroundColor: index % 2 == 1 ? accent : NSColor.white,
                .paragraphStyle: style, .shadow: shadow,
            ]))
        }
        return self.text(string, top: top, x: x, width: width)
    }

    @discardableResult
    func subtitle(_ text: String, top: CGFloat, align: NSTextAlignment = .center, x: CGFloat = 130, width: CGFloat = W - 260,
                  color: NSColor = NSColor.white.withAlphaComponent(0.9)) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineSpacing = 4
        return self.text(NSAttributedString(string: text, attributes: [
            .font: roundedFont(50, .semibold), .foregroundColor: color, .paragraphStyle: style,
        ]), top: top, x: x, width: width)
    }

    /// Draws text in a column; returns where it ends.
    func text(_ string: NSAttributedString, top: CGFloat, x: CGFloat, width: CGFloat) -> CGFloat {
        let bounds = string.boundingRect(with: NSSize(width: width, height: 3000), options: [.usesLineFragmentOrigin, .usesFontLeading])
        let height = ceil(bounds.height)
        string.draw(with: NSRect(x: x, y: top, width: width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading])
        return top + height
    }

    func save(to url: URL) {
        NSGraphicsContext.restoreGraphicsState()
        // App Store screenshots must be opaque: flatten onto RGB and save as high-quality JPEG.
        let opaque = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                               bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        opaque.draw(cg.makeImage()!, in: CGRect(x: 0, y: 0, width: W, height: H))
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, opaque.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
        CGImageDestinationFinalize(destination)
        print(url.path)
    }
}

// MARK: - Pieces

/// The phone: screen inside a dark bezel with a metal rim.
func phone(_ screen: CGImage, screenWidth: CGFloat) -> CGImage {
    let scale = screenWidth / CGFloat(screen.width)
    let screenHeight = CGFloat(screen.height) * scale
    let bezel: CGFloat = 24
    let size = CGSize(width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
    let cg = bitmap(Int(size.width), Int(size.height))
    let radius = 200 * scale
    let body = CGRect(origin: .zero, size: size)
    cg.addPath(CGPath(roundedRect: body, cornerWidth: radius + bezel, cornerHeight: radius + bezel, transform: nil))
    cg.setFillColor(hex(0x101014).cgColor)
    cg.fillPath()
    cg.addPath(CGPath(roundedRect: body.insetBy(dx: 3, dy: 3), cornerWidth: radius + bezel - 3, cornerHeight: radius + bezel - 3, transform: nil))
    cg.setStrokeColor(hex(0x8A8A94).cgColor)
    cg.setLineWidth(5)
    cg.strokePath()
    let screenRect = CGRect(x: bezel, y: bezel, width: screenWidth, height: screenHeight)
    cg.addPath(CGPath(roundedRect: screenRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.interpolationQuality = .high
    cg.draw(screen, in: screenRect)
    return cg.makeImage()!
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

/// A Lock Screen style notification from Tixday.
func notification(title: String, body: String, icon: CGImage) -> CGImage {
    let width: CGFloat = 1060, height: CGFloat = 230
    let cg = bitmap(Int(width), Int(height))
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    let bounds = CGRect(x: 0, y: 0, width: width, height: height)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: 64, cornerHeight: 64, transform: nil))
    cg.setFillColor(NSColor.white.withAlphaComponent(0.94).cgColor)
    cg.fillPath()
    cg.saveGState()
    let iconRect = CGRect(x: 40, y: 51, width: 128, height: 128)
    cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 30, cornerHeight: 30, transform: nil))
    cg.clip()
    cg.translateBy(x: 0, y: iconRect.midY * 2)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(icon, in: iconRect)
    cg.restoreGState()
    let ink = hex(0x16161A)
    NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 46, weight: .bold), .foregroundColor: ink])
        .draw(with: NSRect(x: 200, y: 52, width: width - 240, height: 60), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    NSAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 44, weight: .regular), .foregroundColor: ink.withAlphaComponent(0.8)])
        .draw(with: NSRect(x: 200, y: 118, width: width - 240, height: 60), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    NSGraphicsContext.restoreGraphicsState()
    return cg.makeImage()!
}

/// The red rubber stamp as a big sticker, matching the app's Admitted stamp.
func stampSticker(_ word: String) -> CGImage {
    let font = NSFont.systemFont(ofSize: 120, weight: .black, width: .expanded)
    let red = hex(0xE5483B)
    let text = NSAttributedString(string: word, attributes: [.font: font, .foregroundColor: red])
    let size = text.size()
    let pad: CGFloat = 60
    let width = size.width + pad * 2, height = size.height + pad * 1.4
    let cg = bitmap(Int(width), Int(height))
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    let outer = CGRect(x: 10, y: 10, width: width - 20, height: height - 20)
    cg.addPath(CGPath(roundedRect: outer, cornerWidth: 40, cornerHeight: 40, transform: nil))
    cg.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
    cg.fillPath()
    cg.addPath(CGPath(roundedRect: outer.insetBy(dx: 14, dy: 14), cornerWidth: 30, cornerHeight: 30, transform: nil))
    cg.setStrokeColor(red.cgColor)
    cg.setLineWidth(14)
    cg.strokePath()
    cg.addPath(CGPath(roundedRect: outer.insetBy(dx: 38, dy: 38), cornerWidth: 18, cornerHeight: 18, transform: nil))
    cg.setLineWidth(5)
    cg.strokePath()
    text.draw(at: NSPoint(x: pad, y: (height - size.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    return cg.makeImage()!
}

// MARK: - Slides

struct Content {
    let title: String
    let subtitle: String
    let language: String
    let raw: URL
    func screen(_ name: String) -> CGImage { loadImage(raw.appending(path: "\(name).png"))! }
}

let yellow = hex(0xFFD84D)

func homeSlide(_ c: Canvas, _ content: Content) {
    c.gradient(hex(0x6A45E8), hex(0x1B0F55))
    c.sunburst(CGPoint(x: W / 2, y: 1500), rays: 36, alpha: 0.06)
    c.glow(CGPoint(x: W / 2, y: 1400), radius: 1000)
    let y = c.headline(content.title, top: 150, accent: yellow)
    let sub = c.subtitle(content.subtitle, top: y + 24)
    let screen = content.screen("home")
    let device = phone(screen, screenWidth: 900)
    let top = sub + 120
    c.place(device, center: CGPoint(x: W / 2, y: top + CGFloat(device.height) / 2), width: CGFloat(device.width), shadow: 90)
    let ticket = cut(screen, CGRect(x: 62, y: 442, width: 1196, height: 886), radius: 84)
    c.place(ticket, center: CGPoint(x: W / 2 + 10, y: top + 24 + 900 / 1320 * 885), width: 1180, angle: -4)
    c.sparkle(CGPoint(x: 1210, y: top - 30), size: 46, color: yellow)
    c.sparkle(CGPoint(x: 120, y: top + 1200), size: 30, color: .white)
    c.stub(CGPoint(x: 1220, y: top + 1500), width: 120, angle: 24, color: yellow)
}

func widgetsSlide(_ c: Canvas, _ content: Content) {
    c.gradient(hex(0x19B394), hex(0x03362E))
    c.blob(CGRect(x: -260, y: 700, width: 900, height: 900), color: hex(0xFFFFFF, 0.08))
    c.blob(CGRect(x: 720, y: 1500, width: 900, height: 900), color: hex(0xFFD84D, 0.12))
    c.blob(CGRect(x: 380, y: 2350, width: 700, height: 700), color: hex(0xFFFFFF, 0.06))
    let y = c.headline(content.title, top: 150, accent: yellow)
    let sub = c.subtitle(content.subtitle, top: y + 24)
    let screen = content.screen("widgets")
    let flight = cut(screen, CGRect(x: 80, y: 398, width: 1160, height: 538), radius: 72)
    let concert = cut(screen, CGRect(x: 80, y: 1018, width: 540, height: 540), radius: 72)
    let birthday = cut(screen, CGRect(x: 700, y: 1018, width: 540, height: 540), radius: 72)
    let holiday = cut(screen, CGRect(x: 80, y: 1638, width: 1160, height: 542), radius: 72)
    let top = sub + 70
    c.place(flight, center: CGPoint(x: W / 2, y: top + 290), width: 1140, angle: -3)
    c.place(concert, center: CGPoint(x: 360, y: top + 900), width: 560, angle: -6)
    c.place(birthday, center: CGPoint(x: 960, y: top + 950), width: 560, angle: 5)
    c.place(holiday, center: CGPoint(x: W / 2 + 30, y: top + 1560), width: 1140, angle: 2)
    c.sparkle(CGPoint(x: 1220, y: top + 610), size: 40, color: yellow)
    c.sparkle(CGPoint(x: 90, y: top + 1250), size: 30, color: .white)
    c.stub(CGPoint(x: 160, y: top + 2030), width: 130, angle: -18, color: yellow)
}

func birthdaySlide(_ c: Canvas, _ content: Content) {
    c.gradient(hex(0xFFC23D), hex(0xE24E16))
    c.glow(CGPoint(x: W / 2, y: 700), radius: 900, alpha: 0.3)
    // Headline at the bottom this time: measure it first, then lay out upwards.
    let screen = content.screen("birthday")
    let device = phone(screen, screenWidth: 860)
    let phoneTop: CGFloat = 110
    c.place(device, center: CGPoint(x: W / 2, y: phoneTop + CGFloat(device.height) / 2), width: CGFloat(device.width), angle: 0, shadow: 90)
    // Cover the phone's lower part with the slide colour, so it fades into the text area.
    let fade = CGGradient(colorsSpace: sRGB, colors: [hex(0xE85A19, 0).cgColor, hex(0xE65517).cgColor] as CFArray, locations: [0, 1])!
    c.cg.drawLinearGradient(fade, start: CGPoint(x: 0, y: 1650), end: CGPoint(x: 0, y: 2050), options: [.drawsAfterEndLocation])
    let card = cut(screen, CGRect(x: 62, y: 1328, width: 1196, height: 368), radius: 72)
    c.place(card, center: CGPoint(x: W / 2, y: 1560), width: 1200, angle: -3)
    c.sparkle(CGPoint(x: 1230, y: 1290), size: 44, color: hex(0x2A1366))
    c.stub(CGPoint(x: 110, y: 1830), width: 120, angle: -20, color: .white)
    let y = c.headline(content.title, top: 2140, accent: hex(0x2A1366), maxSize: 128)
    c.subtitle(content.subtitle, top: y + 22)
}

func editorSlide(_ c: Canvas, _ content: Content) {
    c.gradient(hex(0x3C80FF), hex(0x0A1F5C))
    c.blob(CGRect(x: 500, y: 600, width: 1300, height: 1300), color: hex(0xFFFFFF, 0.07))
    let y = c.headline(content.title, top: 150, accent: yellow, align: .natural, x: 90, width: 1140, maxSize: 132)
    let sub = c.subtitle(content.subtitle, top: y + 24, align: .natural, x: 92, width: 1000)
    let screen = content.screen("editor")
    let device = phone(screen, screenWidth: 900)
    let top = sub + 110
    c.place(device, center: CGPoint(x: 900, y: top + CGFloat(device.height) / 2 + 40), width: CGFloat(device.width), angle: 7, shadow: 90)
    // The kind tiles from the editor's picker, fanned down the left side.
    let tiles = [
        CGRect(x: 44, y: 1406, width: 284, height: 346),
        CGRect(x: 356, y: 1432, width: 236, height: 292),
        CGRect(x: 644, y: 1432, width: 236, height: 292),
        CGRect(x: 932, y: 1432, width: 236, height: 292),
    ]
    for (index, rect) in tiles.enumerated() {
        let tile = cut(screen, rect, radius: index == 0 ? 60 : 44)
        c.place(tile, center: CGPoint(x: 250 + CGFloat(index % 2) * 60, y: top + 260 + CGFloat(index) * 400),
                width: index == 0 ? 400 : 340, angle: index % 2 == 0 ? -8 : 6, shadow: 60)
    }
    c.sparkle(CGPoint(x: 1230, y: top - 40), size: 42, color: yellow)
}

func usedSlide(_ c: Canvas, _ content: Content, icon: CGImage, catalog: (String) -> String) {
    c.gradient(hex(0xFF5577), hex(0x4A0B24))
    c.sunburst(CGPoint(x: W / 2, y: 1150), rays: 28, alpha: 0.05)
    c.glow(CGPoint(x: W / 2, y: 1150), radius: 900)
    let y = c.headline(content.title, top: 150, accent: yellow)
    let sub = c.subtitle(content.subtitle, top: y + 24)
    let screen = content.screen("used")
    let ticket = cut(screen, CGRect(x: 62, y: 372, width: 1196, height: 886), radius: 84)
    let top = sub + 80
    c.place(ticket, center: CGPoint(x: W / 2, y: top + 450), width: 1200, angle: -5)
    c.place(stampSticker(catalog("ADMITTED")), center: CGPoint(x: 840, y: top + 860), width: 760, angle: -12, shadow: 40)
    let soon = notification(title: "Coldplay", body: catalog("One week to go!"), icon: icon)
    let tomorrow = notification(title: "Coldplay", body: catalog("Tomorrow's the day!"), icon: icon)
    c.place(soon, center: CGPoint(x: W / 2 - 20, y: top + 1260), width: 1080, angle: 2, shadow: 50)
    c.place(tomorrow, center: CGPoint(x: W / 2 + 20, y: top + 1560), width: 1080, angle: -2, shadow: 50)
    c.sparkle(CGPoint(x: 1220, y: top + 1100), size: 40, color: yellow)
    c.stub(CGPoint(x: 120, y: top + 1850), width: 130, angle: -20, color: yellow)
}

// MARK: - Run

let catalogData = try! Data(contentsOf: root.appending(path: "Tixday/Resources/Localizable.xcstrings"))
let catalogStrings = (try! JSONSerialization.jsonObject(with: catalogData) as! [String: Any])["strings"] as! [String: Any]
func translate(_ key: String, _ language: String) -> String {
    guard let entry = catalogStrings[key] as? [String: Any],
          let localizations = entry["localizations"] as? [String: Any],
          let unit = (localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any],
          let value = unit["value"] as? String else { return key }
    return value
}
let icon = loadImage(root.appending(path: "Tixday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))!

let textsData = try! Data(contentsOf: root.appending(path: "docs/app-store/screenshot-texts.json"))
let texts = try! JSONSerialization.jsonObject(with: textsData) as! [String: Any]
let names = ["home", "widgets", "birthday", "editor", "used"]
for (key, value) in texts.sorted(by: { $0.key < $1.key }) where !key.hasPrefix("_") {
    let locale = storeLocale[key] ?? key
    if !onlyLocales.isEmpty && !onlyLocales.contains(locale) { continue }
    guard let items = value as? [[String]] else { continue }
    let language = appLanguage[key] ?? key
    let raw = rawDir.appending(path: language)
    guard names.allSatisfy({ FileManager.default.fileExists(atPath: raw.appending(path: "\($0).png").path) }) else {
        print("skipping \(key): raw screens missing")
        continue
    }
    let out = outDir.appending(path: locale)
    try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    for (index, name) in names.enumerated() {
        let content = Content(title: items[index][0], subtitle: items[index][1], language: language, raw: raw)
        let canvas = Canvas(locale: Locale(identifier: language))
        switch name {
        case "home": homeSlide(canvas, content)
        case "widgets": widgetsSlide(canvas, content)
        case "birthday": birthdaySlide(canvas, content)
        case "editor": editorSlide(canvas, content)
        default: usedSlide(canvas, content, icon: icon, catalog: { translate($0, language) })
        }
        canvas.save(to: out.appending(path: "\(index + 1)_\(name).jpg"))
    }
}
