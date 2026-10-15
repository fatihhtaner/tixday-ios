// Renders the App Store screenshots: a bold coloured slide per screen with an uppercase headline
// (one *accent* word in colour), a tilted phone running off the bottom, and the key part of the
// screen popping out of the phone. Output is 1320×2868 JPEG (6.9-inch iPhone).
//
// Usage: swift tools/make_store_screenshots.swift <raw-dir> <out-dir> [store-locale …]
//   <raw-dir>/<lang>/{home,widgets,birthday,editor,used}.png come from tools/capture_store_screens.sh;
//   texts from docs/app-store/screenshot-texts.json; writes <out-dir>/<store-locale>/1_home.jpg …,
//   the folder layout fastlane deliver uploads (fastlane/screenshots).
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
/// Text keys are App Store locales; raw captures are named by the app's language codes.
let captureFolder = ["en": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "ar-SA": "ar"]
let storeLocale = ["en": "en-US"]
let textLocale = ["en": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "ar-SA": "ar"]

let W = 1320, H = 2868
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func hex(_ value: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255, alpha: alpha)
}

/// One slide's look. `cutout` is the part of the raw screen (pixels, from the top left) that pops out.
struct Slide {
    let screen: String
    let top: NSColor
    let bottom: NSColor
    let accent: NSColor
    let tilt: CGFloat
    let cutout: CGRect
    let cutoutRadius: CGFloat
    /// Where the pop-out sits, as a fraction of the phone screen's height from its top.
    let cutoutAt: CGFloat
    let cutoutTilt: CGFloat
    let cutoutWidth: CGFloat
}

let slides = [
    Slide(screen: "home", top: hex(0x5B3BD6), bottom: hex(0x1C1057), accent: hex(0xFFD84D), tilt: -5,
          cutout: CGRect(x: 62, y: 442, width: 1196, height: 886), cutoutRadius: 84, cutoutAt: 0.17, cutoutTilt: 3, cutoutWidth: 1150),
    Slide(screen: "widgets", top: hex(0x14A085), bottom: hex(0x04362E), accent: hex(0xFFD84D), tilt: 5,
          cutout: CGRect(x: 80, y: 398, width: 1160, height: 538), cutoutRadius: 72, cutoutAt: 0.16, cutoutTilt: -4, cutoutWidth: 1130),
    Slide(screen: "birthday", top: hex(0xFFB02E), bottom: hex(0xE0561B), accent: hex(0x2A1366), tilt: -5,
          cutout: CGRect(x: 62, y: 1328, width: 1196, height: 368), cutoutRadius: 72, cutoutAt: 0.44, cutoutTilt: 3, cutoutWidth: 1160),
    Slide(screen: "editor", top: hex(0x2F74F0), bottom: hex(0x0B2463), accent: hex(0xFFD84D), tilt: 5,
          cutout: CGRect(x: 44, y: 1406, width: 1246, height: 346), cutoutRadius: 60, cutoutAt: 0.47, cutoutTilt: -3, cutoutWidth: 1200),
    Slide(screen: "used", top: hex(0xF0476A), bottom: hex(0x5E0F2D), accent: hex(0xFFD84D), tilt: -5,
          cutout: CGRect(x: 62, y: 372, width: 1196, height: 886), cutoutRadius: 84, cutoutAt: 0.15, cutoutTilt: 4, cutoutWidth: 1150),
]

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

/// "Her tarih\nbir *bilet*" → an uppercase attributed headline with the starred words in the accent colour.
func headline(_ text: String, locale: Locale, size: CGFloat, accent: NSColor) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineHeightMultiple = 0.9
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: 0, height: -7)
    shadow.shadowBlurRadius = 0
    let result = NSMutableAttributedString()
    for (index, part) in text.uppercased(with: locale).components(separatedBy: "*").enumerated() {
        result.append(NSAttributedString(string: part, attributes: [
            .font: roundedFont(size, .black),
            .foregroundColor: index % 2 == 1 ? accent : NSColor.white,
            .paragraphStyle: style,
            .shadow: shadow,
        ]))
    }
    return result
}

/// The largest size (up to 138) at which every explicit headline line fits.
func headlineSize(_ text: String, locale: Locale, maxWidth: CGFloat) -> CGFloat {
    var size: CGFloat = 138
    while size > 70 {
        let plain = text.replacingOccurrences(of: "*", with: "").uppercased(with: locale)
        let fits = plain.split(separator: "\n").allSatisfy {
            NSAttributedString(string: String($0), attributes: [.font: roundedFont(size, .black)]).size().width <= maxWidth
        }
        if fits { return size }
        size -= 4
    }
    return size
}

/// Draws centred text with its top `top` points below the canvas top; returns where it ends.
@discardableResult
func draw(_ string: NSAttributedString, top: CGFloat, width: CGFloat) -> CGFloat {
    let bounds = string.boundingRect(with: NSSize(width: width, height: 3000), options: [.usesLineFragmentOrigin, .usesFontLeading])
    let height = ceil(bounds.height)
    string.draw(with: NSRect(x: (CGFloat(W) - width) / 2, y: CGFloat(H) - top - height, width: width, height: height),
                options: [.usesLineFragmentOrigin, .usesFontLeading])
    return top + height
}

func sparkle(_ cg: CGContext, center: CGPoint, size: CGFloat, color: NSColor) {
    let path = CGMutablePath()
    let inner = size * 0.18
    path.move(to: CGPoint(x: center.x, y: center.y + size))
    path.addQuadCurve(to: CGPoint(x: center.x + size, y: center.y), control: CGPoint(x: center.x + inner, y: center.y + inner))
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - size), control: CGPoint(x: center.x + inner, y: center.y - inner))
    path.addQuadCurve(to: CGPoint(x: center.x - size, y: center.y), control: CGPoint(x: center.x - inner, y: center.y - inner))
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + size), control: CGPoint(x: center.x - inner, y: center.y + inner))
    cg.addPath(path)
    cg.setFillColor(color.cgColor)
    cg.fillPath()
}

/// A little tear-off ticket stub, for confetti.
func stub(_ cg: CGContext, center: CGPoint, width: CGFloat, angle: CGFloat, color: NSColor) {
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

/// The phone: screen inside a dark bezel with a metal rim, as its own image.
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

/// A rounded piece of the raw screen.
func cutout(_ screen: CGImage, rect: CGRect, radius: CGFloat) -> CGImage {
    let piece = screen.cropping(to: rect)!
    let cg = bitmap(piece.width, piece.height)
    let bounds = CGRect(x: 0, y: 0, width: piece.width, height: piece.height)
    cg.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.draw(piece, in: bounds)
    return cg.makeImage()!
}

/// Draws an image centred on `center`, rotated by `angle` degrees, with a soft drop shadow.
func place(_ cg: CGContext, _ image: CGImage, center: CGPoint, width: CGFloat, angle: CGFloat, shadow: CGFloat) {
    let height = width * CGFloat(image.height) / CGFloat(image.width)
    cg.saveGState()
    cg.translateBy(x: center.x, y: center.y)
    cg.rotate(by: angle * .pi / 180)
    cg.setShadow(offset: CGSize(width: 0, height: -shadow * 0.5), blur: shadow, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    cg.interpolationQuality = .high
    cg.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
    cg.restoreGState()
}

func render(_ slide: Slide, screen: CGImage, to outURL: URL, title: String, subtitle: String, locale: Locale) {
    let cg = bitmap(W, H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)

    // Background: a vertical gradient with a soft glow behind the phone.
    let gradient = CGGradient(colorsSpace: sRGB, colors: [slide.top.cgColor, slide.bottom.cgColor] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    let glow = CGGradient(colorsSpace: sRGB, colors: [NSColor.white.withAlphaComponent(0.22).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    cg.drawRadialGradient(glow, startCenter: CGPoint(x: W / 2, y: H / 2), startRadius: 0,
                          endCenter: CGPoint(x: W / 2, y: H / 2), endRadius: 1100, options: [])

    // Confetti: ticket stubs and sparkles around the edges.
    // Top decorations stay in the corners, clear of the headline.
    stub(cg, center: CGPoint(x: 70, y: H - 70), width: 110, angle: -24, color: slide.accent.withAlphaComponent(0.9))
    stub(cg, center: CGPoint(x: 1230, y: H - 760), width: 92, angle: 28, color: NSColor.white.withAlphaComponent(0.85))
    stub(cg, center: CGPoint(x: 110, y: 1180), width: 84, angle: 18, color: NSColor.white.withAlphaComponent(0.8))
    sparkle(cg, center: CGPoint(x: 1250, y: H - 90), size: 38, color: slide.accent)
    sparkle(cg, center: CGPoint(x: 210, y: H - 720), size: 26, color: .white)
    sparkle(cg, center: CGPoint(x: 1240, y: 1500), size: 34, color: .white)

    // Headline and subtitle.
    let size = headlineSize(title, locale: locale, maxWidth: 1180)
    var y = draw(headline(title, locale: locale, size: size, accent: slide.accent), top: 150, width: 1240)
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineSpacing = 4
    y = draw(NSAttributedString(string: subtitle, attributes: [
        .font: roundedFont(48, .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.88), .paragraphStyle: style,
    ]), top: y + 26, width: 1060)

    // Tilted phone running off the bottom, then the key part popping out of it.
    let screenWidth: CGFloat = 960
    let device = phone(screen, screenWidth: screenWidth)
    let deviceWidth = CGFloat(device.width)
    let deviceHeight = CGFloat(device.height)
    let phoneTop = y + 110
    let center = CGPoint(x: CGFloat(W) / 2, y: CGFloat(H) - phoneTop - deviceHeight / 2)
    place(cg, device, center: center, width: deviceWidth, angle: slide.tilt, shadow: 90)

    let piece = cutout(screen, rect: slide.cutout, radius: slide.cutoutRadius)
    let pieceHeight = slide.cutoutWidth * CGFloat(piece.height) / CGFloat(piece.width)
    let pieceCenterY = CGFloat(H) - phoneTop - 24 - deviceHeight * slide.cutoutAt - pieceHeight / 2
    place(cg, piece, center: CGPoint(x: CGFloat(W) / 2, y: pieceCenterY), width: slide.cutoutWidth, angle: slide.cutoutTilt, shadow: 70)

    NSGraphicsContext.restoreGraphicsState()

    // App Store screenshots must be opaque: flatten onto RGB and save as high-quality JPEG.
    let opaque = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    opaque.draw(cg.makeImage()!, in: CGRect(x: 0, y: 0, width: W, height: H))
    let destination = CGImageDestinationCreateWithURL(outURL as CFURL, "public.jpeg" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, opaque.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
    CGImageDestinationFinalize(destination)
    print(outURL.path)
}

let textsData = try! Data(contentsOf: root.appending(path: "docs/app-store/screenshot-texts.json"))
let texts = try! JSONSerialization.jsonObject(with: textsData) as! [String: Any]
for (key, value) in texts.sorted(by: { $0.key < $1.key }) where !key.hasPrefix("_") {
    let locale = storeLocale[key] ?? key
    if !onlyLocales.isEmpty && !onlyLocales.contains(locale) { continue }
    guard let items = value as? [[String]] else { continue }
    let raw = rawDir.appending(path: captureFolder[key] ?? key)
    let out = outDir.appending(path: locale)
    try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    for (index, (slide, item)) in zip(slides, items).enumerated() {
        guard let screen = loadImage(raw.appending(path: "\(slide.screen).png")) else {
            print("skipping \(key)/\(slide.screen): raw screen missing")
            continue
        }
        render(slide, screen: screen, to: out.appending(path: "\(index + 1)_\(slide.screen).jpg"),
               title: item[0], subtitle: item[1], locale: Locale(identifier: textLocale[key] ?? key))
    }
}
