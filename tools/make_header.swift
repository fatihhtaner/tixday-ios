// Renders the App Store product page header (and universal search-results asset), following Apple's
// creative asset guidance: one clear idea, centred so nothing important is cropped, no feature list.
// A centred headline over a fan of real tickets taken from the app.
//
// Usage: swift tools/make_header.swift <raw-dir> <out-dir>
//   <raw-dir>/<lang>/{widgets,used}.png come from tools/capture_store_screens.sh.
//   Writes <out-dir>/header-16x9-<lang>.png (5244×2950, PNG only; header and search results)
//   and <out-dir>/header-21x9-<lang>.jpg (3840×1646, header).
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make_header.swift <raw-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

/// `*word*` is drawn in yellow.
let copy: [String: (headline: String, subtitle: String)] = [
    "en": ("Every date is a *ticket*", "Countdown widgets with vintage poster art"),
    "tr": ("Her tarih bir *bilet*", "Vintage posterli geri sayım widget'ları"),
]

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

func cut(_ image: CGImage, _ rect: CGRect, radius: CGFloat) -> CGImage {
    let piece = image.cropping(to: rect)!
    let cg = bitmap(piece.width, piece.height)
    let bounds = CGRect(x: 0, y: 0, width: piece.width, height: piece.height)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.draw(piece, in: bounds)
    return cg.makeImage()!
}

/// Draws one header. The layout is designed 1260 units high and centred, so wider shapes only add background.
func render(language: String, pixelWidth: CGFloat, pixelHeight: CGFloat, to url: URL, png: Bool) {
    let raw = rawDir.appending(path: language)
    guard let widgets = loadImage(raw.appending(path: "widgets.png")), let used = loadImage(raw.appending(path: "used.png")),
          let text = copy[language] else {
        print("skipping \(language)")
        return
    }
    let H: CGFloat = 1260
    let scale = pixelHeight / H
    let W = pixelWidth / scale
    let cx = W / 2

    let cg = bitmap(Int(pixelWidth), Int(pixelHeight))
    cg.scaleBy(x: scale, y: scale)
    cg.translateBy(x: 0, y: H)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    // Background: violet to concert pink, rays from behind the tickets, a soft glow.
    let gradient = CGGradient(colorsSpace: sRGB, colors: [hex(0x2A1460).cgColor, hex(0x5A2DBE).cgColor, hex(0xB8346C).cgColor] as CFArray,
                              locations: [0, 0.6, 1])!
    cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    // Below the bottom edge, so the rays only fan upwards (no seam where they meet).
    let sun = CGPoint(x: cx, y: 1560)
    cg.setFillColor(NSColor.white.withAlphaComponent(0.05).cgColor)
    let rays = 40, step = CGFloat.pi * 2 / CGFloat(rays)
    for index in stride(from: 0, to: rays, by: 2) {
        let a = CGFloat(index) * step
        cg.move(to: sun)
        cg.addLine(to: CGPoint(x: sun.x + cos(a) * 4000, y: sun.y + sin(a) * 4000))
        cg.addLine(to: CGPoint(x: sun.x + cos(a + step) * 4000, y: sun.y + sin(a + step) * 4000))
        cg.closePath()
    }
    cg.fillPath()
    let glow = CGGradient(colorsSpace: sRGB, colors: [NSColor.white.withAlphaComponent(0.28).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    cg.drawRadialGradient(glow, startCenter: CGPoint(x: cx, y: 860), startRadius: 0, endCenter: CGPoint(x: cx, y: 860), endRadius: 760, options: [])

    // Headline, centred.
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: 8)
    let locale = Locale(identifier: language)
    let headline = NSMutableAttributedString()
    for (index, part) in text.headline.uppercased(with: locale).components(separatedBy: "*").enumerated() {
        headline.append(NSAttributedString(string: part, attributes: [
            .font: roundedFont(132, .black), .foregroundColor: index % 2 == 1 ? yellow : NSColor.white,
            .paragraphStyle: style, .shadow: shadow,
        ]))
    }
    headline.draw(with: NSRect(x: cx - 1100, y: 130, width: 2200, height: 180), options: [.usesLineFragmentOrigin])
    NSAttributedString(string: text.subtitle, attributes: [
        .font: roundedFont(48, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.85), .paragraphStyle: style,
    ]).draw(with: NSRect(x: cx - 1000, y: 300, width: 2000, height: 70), options: [.usesLineFragmentOrigin])

    // The fan: real tickets from the widget screen, the stamped one on the right.
    func place(_ image: CGImage, center: CGPoint, width: CGFloat, angle: CGFloat) {
        let height = width * CGFloat(image.height) / CGFloat(image.width)
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: angle * .pi / 180)
        cg.scaleBy(x: 1, y: -1)
        cg.setShadow(offset: CGSize(width: 0, height: -30), blur: 60, color: NSColor.black.withAlphaComponent(0.45).cgColor)
        cg.interpolationQuality = .high
        cg.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        cg.restoreGState()
    }
    let concert = cut(widgets, CGRect(x: 80, y: 1018, width: 540, height: 540), radius: 72)
    let birthday = cut(widgets, CGRect(x: 700, y: 1018, width: 540, height: 540), radius: 72)
    let wedding = cut(widgets, CGRect(x: 700, y: 2258, width: 540, height: 540), radius: 72)
    let flight = cut(widgets, CGRect(x: 80, y: 398, width: 1160, height: 538), radius: 72)
    let stamped = cut(used, CGRect(x: 62, y: 372, width: 1196, height: 886), radius: 84)
    place(wedding, center: CGPoint(x: cx - 760, y: 900), width: 360, angle: -14)
    place(stamped, center: CGPoint(x: cx + 700, y: 880), width: 520, angle: 12)
    place(concert, center: CGPoint(x: cx - 450, y: 820), width: 400, angle: -7)
    place(birthday, center: CGPoint(x: cx + 410, y: 830), width: 400, angle: 7)
    place(flight, center: CGPoint(x: cx, y: 800), width: 700, angle: 0)

    NSGraphicsContext.restoreGraphicsState()
    // No alpha channel allowed: flatten onto opaque RGB.
    let opaque = CGContext(data: nil, width: Int(pixelWidth), height: Int(pixelHeight), bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    opaque.draw(cg.makeImage()!, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
    let destination = CGImageDestinationCreateWithURL(url as CFURL, (png ? "public.png" : "public.jpeg") as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, opaque.makeImage()!, png ? nil : [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
    CGImageDestinationFinalize(destination)
    print(url.path)
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
for language in copy.keys.sorted() {
    render(language: language, pixelWidth: 5244, pixelHeight: 2950, to: outDir.appending(path: "header-16x9-\(language).png"), png: true)
    render(language: language, pixelWidth: 3840, pixelHeight: 1646, to: outDir.appending(path: "header-21x9-\(language).jpg"), png: false)
}
