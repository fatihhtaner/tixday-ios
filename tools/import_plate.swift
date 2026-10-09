// Imports AI-made ticket plates into the shared asset catalog.
// Usage (from the repo root): swift tools/import_plate.swift <kind>
// Reads design/plate-<kind>-wide.png and design/plate-<kind>-square.png. The wide plate is split at the
// stub seam (the tone change in the right third, found automatically, or at 71% if there is none) so the
// printed fold lines up with the code-drawn perforation. Outputs are downscaled for the widget memory limit.
import AppKit

let kind = CommandLine.arguments.dropFirst().first ?? { fatalError("Usage: swift tools/import_plate.swift <kind>") }()
let catalog = "Tixday/Tickets/TicketArt.xcassets"

func load(_ path: String) -> CGImage {
    guard let data = FileManager.default.contents(atPath: path), let rep = NSBitmapImageRep(data: data), let image = rep.cgImage else {
        fatalError("Can't read \(path)")
    }
    return image
}

/// Column with the biggest brightness step over the plain top 40%, searched between 60% and 82% of the width.
func seam(in image: CGImage) -> Int {
    let rep = NSBitmapImageRep(cgImage: image)
    let w = rep.pixelsWide, h = rep.pixelsHigh
    func column(_ x: Int) -> Double {
        stride(from: 10, to: Int(Double(h) * 0.4), by: 6).reduce(0) { $0 + rep.colorAt(x: x, y: $1)!.brightnessComponent }
    }
    var best = (x: Int(Double(w) * 0.71), step: 0.0)
    for x in Int(Double(w) * 0.6)..<Int(Double(w) * 0.82) {
        let step = abs(column(x + 3) - column(x - 3))
        if step > best.step { best = (x, step) }
    }
    // A real seam stands out clearly; otherwise keep the default split.
    return best.step > 0.5 ? best.x : Int(Double(w) * 0.71)
}

func write(_ image: CGImage, name: String, maxSide: Int) {
    let scale = min(1, Double(maxSide) / Double(max(image.width, image.height)))
    let size = NSSize(width: Int(Double(image.width) * scale), height: Int(Double(image.height) * scale))
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSImage(cgImage: image, size: size).draw(in: NSRect(origin: .zero, size: size))
    NSGraphicsContext.restoreGraphicsState()

    let folder = "\(catalog)/\(name).imageset"
    try! FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(folder)/\(name).png"))
    let contents = #"{ "images" : [ { "filename" : "\#(name).png", "idiom" : "universal" } ], "info" : { "author" : "xcode", "version" : 1 } }"#
    try! contents.write(toFile: "\(folder)/Contents.json", atomically: true, encoding: .utf8)
    print("\(name): \(Int(size.width))x\(Int(size.height))")
}

let wide = load("design/plate-\(kind)-wide.png")
let x = seam(in: wide)
print("seam at \(x) of \(wide.width) (\(x * 100 / wide.width)%)")
write(wide.cropping(to: CGRect(x: 0, y: 0, width: x - 4, height: wide.height))!, name: "plate-\(kind)-body", maxSide: 800)
write(wide.cropping(to: CGRect(x: x + 4, y: 0, width: wide.width - x - 4, height: wide.height))!, name: "plate-\(kind)-stub", maxSide: 520)
write(load("design/plate-\(kind)-square.png"), name: "plate-\(kind)-square", maxSide: 600)
