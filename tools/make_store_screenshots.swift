// Renders the App Store screenshots: each raw simulator screen in a phone frame on its own blurred,
// darkened colours, under a headline and subtitle. Output is 1320×2868 (6.9-inch iPhone).
//
// Usage: swift tools/make_store_screenshots.swift <raw-dir> <out-dir>
//   <raw-dir>/<lang>/{home,widgets,birthday,editor,used}.png come from tools/capture_store_screens.sh;
//   texts from docs/app-store/screenshot-texts.json; writes <out-dir>/<store-locale>/1_<screen>.jpg …,
//   which is the folder layout fastlane deliver uploads (fastlane/screenshots).
// CoreText draws every script, including Arabic (right to left) and Japanese, Korean and Chinese.
import AppKit
import CoreImage

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: make_store_screenshots.swift <raw-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let rawDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let screens = ["home", "widgets", "birthday", "editor", "used"]
/// Text keys are App Store locales; raw captures are named by the app's language codes.
let captureFolder = ["en": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "ar-SA": "ar"]
let storeLocale = ["en": "en-US"]

let W = 1320, H = 2868
let ciContext = CIContext()

func cgImage(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

/// The poster behind each screen, so every shot has its own colours.
let backdropPoster = ["home": "concert", "widgets": "holiday", "birthday": "birthday", "editor": "flight", "used": "concert"]

/// A poster scaled to fill, heavily blurred and darkened.
func backdrop(_ poster: CGImage) -> CGImage {
    let input = CIImage(cgImage: poster)
    let scale = max(CGFloat(W) / input.extent.width, CGFloat(H) / input.extent.height) * 1.15
    let scaled = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale)).clampedToExtent()
    let blurred = scaled.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 90])
    let darker = blurred.applyingFilter("CIColorControls", parameters: [
        kCIInputBrightnessKey: -0.28, kCIInputSaturationKey: 1.1,
    ])
    let rect = CGRect(x: (input.extent.width * scale - CGFloat(W)) / 2, y: (input.extent.height * scale - CGFloat(H)) / 2,
                      width: CGFloat(W), height: CGFloat(H))
    return ciContext.createCGImage(darker, from: rect)!
}

func displayFont(_ size: CGFloat) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: .black, width: .expanded)
}

func paragraph() -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineBreakMode = .byWordWrapping
    return style
}

/// Draws centred text in a column starting at `top` (from the top edge); returns where it ends.
@discardableResult
func drawText(_ text: String, font: NSFont, color: NSColor, top: CGFloat, width: CGFloat, lineSpacing: CGFloat = 0) -> CGFloat {
    let style = paragraph()
    style.lineSpacing = lineSpacing
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    let bounds = string.boundingRect(with: NSSize(width: width, height: 2000), options: [.usesLineFragmentOrigin, .usesFontLeading])
    let rect = NSRect(x: (CGFloat(W) - width) / 2, y: CGFloat(H) - top - ceil(bounds.height), width: width, height: ceil(bounds.height))
    string.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    return top + ceil(bounds.height)
}

/// The largest headline size (up to 128) at which every explicit line fits on one line.
func headlineFont(_ headline: String, maxWidth: CGFloat) -> NSFont {
    var size: CGFloat = 128
    while size > 72 {
        let font = displayFont(size)
        let fits = headline.split(separator: "\n").allSatisfy { line in
            NSAttributedString(string: String(line), attributes: [.font: font]).size().width <= maxWidth
        }
        if fits { return font }
        size -= 4
    }
    return displayFont(size)
}

func render(screen screenURL: URL, poster posterURL: URL, to outURL: URL, headline: String, subtitle: String) {
    guard let screen = cgImage(screenURL), let poster = cgImage(posterURL) else { print("missing \(screenURL.path)"); return }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext

    cg.draw(backdrop(poster), in: CGRect(x: 0, y: 0, width: W, height: H))
    // A soft dark wash behind the text keeps it readable on bright posters.
    let wash = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [NSColor.black.withAlphaComponent(0.45).cgColor, NSColor.black.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    cg.drawLinearGradient(wash, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: H - 1100), options: [])

    var y = drawText(headline, font: headlineFont(headline, maxWidth: 1200), color: .white, top: 190, width: 1240, lineSpacing: -6)
    y = drawText(subtitle, font: .systemFont(ofSize: 50, weight: .medium), color: NSColor.white.withAlphaComponent(0.8),
                 top: y + 34, width: 1080, lineSpacing: 6)

    // The phone runs off the bottom edge, so screens with space at the bottom still look full.
    let screenWidth: CGFloat = 1060
    let scale = screenWidth / CGFloat(screen.width)
    let screenHeight = CGFloat(screen.height) * scale
    let bezel: CGFloat = 26
    let top = y + 96
    let screenRect = CGRect(x: (CGFloat(W) - screenWidth) / 2, y: CGFloat(H) - top - bezel - screenHeight,
                            width: screenWidth, height: screenHeight)
    let bodyRect = screenRect.insetBy(dx: -bezel, dy: -bezel)
    let radius = 200 * scale

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -40), blur: 120, color: NSColor.black.withAlphaComponent(0.6).cgColor)
    cg.addPath(CGPath(roundedRect: bodyRect, cornerWidth: radius + bezel, cornerHeight: radius + bezel, transform: nil))
    cg.setFillColor(NSColor(srgbRed: 0.07, green: 0.07, blue: 0.08, alpha: 1).cgColor)
    cg.fillPath()
    cg.restoreGState()
    // Metal rim.
    cg.addPath(CGPath(roundedRect: bodyRect.insetBy(dx: 3, dy: 3), cornerWidth: radius + bezel - 3, cornerHeight: radius + bezel - 3, transform: nil))
    cg.setStrokeColor(NSColor(white: 0.42, alpha: 1).cgColor)
    cg.setLineWidth(4)
    cg.strokePath()

    cg.saveGState()
    cg.addPath(CGPath(roundedRect: screenRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.clip()
    cg.interpolationQuality = .high
    cg.draw(screen, in: screenRect)
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    // App Store screenshots must not have an alpha channel: redraw onto an opaque RGB bitmap.
    let opaque = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    opaque.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: W, height: H))
    // High-quality JPEG: a fraction of the PNG size, which the App Store accepts.
    let destination = CGImageDestinationCreateWithURL(outURL as CFURL, "public.jpeg" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, opaque.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
    CGImageDestinationFinalize(destination)
    print(outURL.path)
}

let textsData = try! Data(contentsOf: root.appending(path: "docs/app-store/screenshot-texts.json"))
let texts = try! JSONSerialization.jsonObject(with: textsData) as! [String: Any]
for (key, value) in texts.sorted(by: { $0.key < $1.key }) where !key.hasPrefix("_") {
    guard let items = value as? [[String]] else { continue }
    let raw = rawDir.appending(path: captureFolder[key] ?? key)
    guard screens.allSatisfy({ FileManager.default.fileExists(atPath: raw.appending(path: "\($0).png").path) }) else {
        print("skipping \(key): raw screens missing")
        continue
    }
    let out = outDir.appending(path: storeLocale[key] ?? key)
    try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    for (index, (screen, item)) in zip(screens, items).enumerated() {
        let poster = root.appending(path: "design/poster-\(backdropPoster[screen]!)-wide.png")
        render(screen: raw.appending(path: "\(screen).png"), poster: poster, to: out.appending(path: "\(index + 1)_\(screen).jpg"),
               headline: item[0], subtitle: item[1])
    }
}
