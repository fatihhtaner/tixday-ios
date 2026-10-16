// Renders a wide promo banner (2400×1260, the Open Graph ratio) for the website header, link previews
// and social posts: headline and the new features on the left, a tilted phone with tickets on the right.
//
// Usage: swift tools/make_banner.swift <raw-dir> <out-dir>
//   <raw-dir>/<lang>/{home,widgets,used}.png come from tools/capture_store_screens.sh;
//   writes <out-dir>/banner-<lang>.jpg for every language in `copy` below.
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make_banner.swift <raw-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

let W: CGFloat = 2400, H: CGFloat = 1260
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

struct Copy {
    let headline: String
    let subtitle: String
    let features: [(symbol: String, text: String)]
}

/// `*word*` is drawn in yellow.
let copy: [String: Copy] = [
    "en": Copy(headline: "Every date\nis a *ticket*",
               subtitle: "Countdown widgets with vintage poster art.",
               features: [("repeat", "Birthdays repeat every year"),
                          ("photo", "Your own photos, framed your way"),
                          ("lock.rectangle", "Home and Lock Screen widgets"),
                          ("icloud", "Backed up to your iCloud"),
                          ("checkmark.seal", "An Admitted stamp when the day comes")]),
    "tr": Copy(headline: "Her tarih\nbir *bilet*",
               subtitle: "Vintage posterli geri sayım widget'ları.",
               features: [("repeat", "Doğum günleri her yıl tekrarlar"),
                          ("photo", "Kendi fotoğrafın, istediğin kadrajla"),
                          ("lock.rectangle", "Ana ekran ve kilit ekranı widget'ları"),
                          ("icloud", "iCloud'una yedeklenir"),
                          ("checkmark.seal", "O gün gelince “Onaylandı” damgası")]),
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

func phone(_ screen: CGImage, screenWidth: CGFloat) -> CGImage {
    let scale = screenWidth / CGFloat(screen.width)
    let screenHeight = CGFloat(screen.height) * scale
    let bezel: CGFloat = 18
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

func cut(_ image: CGImage, _ rect: CGRect, radius: CGFloat) -> CGImage {
    let piece = image.cropping(to: rect)!
    let cg = bitmap(piece.width, piece.height)
    let bounds = CGRect(x: 0, y: 0, width: piece.width, height: piece.height)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.draw(piece, in: bounds)
    return cg.makeImage()!
}

func render(_ language: String, _ text: Copy) {
    let raw = rawDir.appending(path: language)
    guard let home = loadImage(raw.appending(path: "home.png")),
          let widgets = loadImage(raw.appending(path: "widgets.png")),
          let used = loadImage(raw.appending(path: "used.png")) else {
        print("skipping \(language): raw screens missing")
        return
    }
    let cg = bitmap(Int(W), Int(H))
    cg.translateBy(x: 0, y: H)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    // Background: deep violet into concert pink, sunburst behind the phone.
    let gradient = CGGradient(colorsSpace: sRGB, colors: [hex(0x24124F).cgColor, hex(0x5B2BB8).cgColor, hex(0xC2366E).cgColor] as CFArray,
                              locations: [0, 0.55, 1])!
    cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: W, y: H), options: [])
    let sun = CGPoint(x: 1780, y: 640)
    cg.setFillColor(NSColor.white.withAlphaComponent(0.05).cgColor)
    let rays = 32, step = CGFloat.pi * 2 / CGFloat(rays)
    for index in stride(from: 0, to: rays, by: 2) {
        let a = CGFloat(index) * step
        cg.move(to: sun)
        cg.addLine(to: CGPoint(x: sun.x + cos(a) * 3000, y: sun.y + sin(a) * 3000))
        cg.addLine(to: CGPoint(x: sun.x + cos(a + step) * 3000, y: sun.y + sin(a + step) * 3000))
        cg.closePath()
    }
    cg.fillPath()
    let glow = CGGradient(colorsSpace: sRGB, colors: [NSColor.white.withAlphaComponent(0.25).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    cg.drawRadialGradient(glow, startCenter: sun, startRadius: 0, endCenter: sun, endRadius: 700, options: [])

    // Left: app icon + name, headline, subtitle, feature list.
    let icon = loadImage(root.appending(path: "Tixday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))!
    cg.saveGState()
    let iconRect = CGRect(x: 130, y: 110, width: 96, height: 96)
    cg.addPath(CGPath(roundedRect: iconRect, cornerWidth: 22, cornerHeight: 22, transform: nil))
    cg.clip()
    cg.translateBy(x: 0, y: iconRect.midY * 2)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(icon, in: iconRect)
    cg.restoreGState()
    NSAttributedString(string: "Tixday", attributes: [.font: roundedFont(52, .heavy), .foregroundColor: NSColor.white])
        .draw(at: NSPoint(x: 250, y: 124))

    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 0.88
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: 7)
    let headline = NSMutableAttributedString()
    let locale = Locale(identifier: language)
    for (index, part) in text.headline.uppercased(with: locale).components(separatedBy: "*").enumerated() {
        headline.append(NSAttributedString(string: part, attributes: [
            .font: roundedFont(150, .black), .foregroundColor: index % 2 == 1 ? yellow : NSColor.white,
            .paragraphStyle: style, .shadow: shadow,
        ]))
    }
    let headRect = headline.boundingRect(with: NSSize(width: 1150, height: 600), options: [.usesLineFragmentOrigin, .usesFontLeading])
    headline.draw(with: NSRect(x: 128, y: 250, width: 1150, height: ceil(headRect.height)), options: [.usesLineFragmentOrigin, .usesFontLeading])
    var y = 250 + ceil(headRect.height) + 26
    NSAttributedString(string: text.subtitle, attributes: [.font: roundedFont(46, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.85)])
        .draw(with: NSRect(x: 132, y: y, width: 1100, height: 70), options: [.usesLineFragmentOrigin])
    y += 110
    for feature in text.features {
        let pill = CGRect(x: 128, y: y, width: 74, height: 74)
        cg.addPath(CGPath(roundedRect: pill, cornerWidth: 22, cornerHeight: 22, transform: nil))
        cg.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
        cg.fillPath()
        if let symbol = NSImage(systemSymbolName: feature.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 34, weight: .semibold).applying(.init(paletteColors: [yellow]))) {
            let size = symbol.size
            symbol.draw(in: NSRect(x: pill.midX - size.width / 2, y: pill.midY - size.height / 2, width: size.width, height: size.height))
        }
        NSAttributedString(string: feature.text, attributes: [.font: roundedFont(42, .bold), .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: 228, y: y + 12))
        y += 98
    }

    // Right: tilted phone with the home screen, a widget and the stamped ticket popping out.
    func place(_ image: CGImage, center: CGPoint, width: CGFloat, angle: CGFloat, shadow: CGFloat = 60) {
        let height = width * CGFloat(image.height) / CGFloat(image.width)
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: angle * .pi / 180)
        cg.scaleBy(x: 1, y: -1)
        cg.setShadow(offset: CGSize(width: 0, height: -shadow * 0.45), blur: shadow, color: NSColor.black.withAlphaComponent(0.45).cgColor)
        cg.interpolationQuality = .high
        cg.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        cg.restoreGState()
    }
    let device = phone(home, screenWidth: 560)
    place(device, center: CGPoint(x: 1800, y: 760), width: CGFloat(device.width), angle: 6, shadow: 90)
    let widget = cut(widgets, CGRect(x: 80, y: 398, width: 1160, height: 538), radius: 72)
    place(widget, center: CGPoint(x: 1560, y: 330), width: 620, angle: -6)
    let ticket = cut(used, CGRect(x: 62, y: 372, width: 1196, height: 886), radius: 84)
    place(ticket, center: CGPoint(x: 2070, y: 1010), width: 560, angle: 8)

    NSGraphicsContext.restoreGraphicsState()
    let opaque = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    opaque.draw(cg.makeImage()!, in: CGRect(x: 0, y: 0, width: W, height: H))
    let url = outDir.appending(path: "banner-\(language).jpg")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, opaque.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    CGImageDestinationFinalize(destination)
    print(url.path)
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
for (language, text) in copy.sorted(by: { $0.key < $1.key }) {
    render(language, text)
}
