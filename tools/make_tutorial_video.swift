// Builds a tutorial video (TikTok / Reels / Shorts, 1080×1920) from simulator clips
// (tools/capture_tutorial_clips.sh): a hook card, numbered steps with a caption above the phone, zooms,
// tap rings on what gets tapped, a bonus step, the closing card and an optional spoken voiceover
// (macOS `say`; the voice comes from the spec, e.g. "Samantha" for English).
// Adapted from Subloom's tool, in Tixday's dark violet/pink look.
//
// Usage: swift tools/make_tutorial_video.swift <spec.json> <clips-dir> <out.mp4> [--silent]   (run from the repo root)
// Spec: docs/marketing/tutorial/episode-1.json. Scene times are seconds in the clip; zoom and tap times
// are seconds from the scene start; positions are fractions of the screen (0,0 = top left).
import AppKit
import AVFoundation
import QuartzCore

struct Zoom: Decodable { let at: Double; let until: Double; let scale: Double; let x: Double; let y: Double }
struct Tap: Decodable { let at: Double; let x: Double; let y: Double }
struct Scene: Decodable {
    let clip: String; let start: Double; let end: Double
    /// "1", "2", "3", "★" (bonus) or nil for the hook scene, which the hook card covers.
    let badge: String?; let caption: String?
    let zoom: Zoom?; let taps: [Tap]?
    /// Spoken from the start of the scene.
    let voice: String?
}
struct Hook: Decodable { let title: String; let subtitle: String }
struct Closing: Decodable { let title: String; let subtitle: String; let seconds: Double; let voice: String? }
struct Spec: Decodable {
    /// Optional label at the top (e.g. "Countdown Guide · Part 1"); omitted when nil.
    let series: String?; let hook: Hook; let scenes: [Scene]; let closing: Closing
    /// macOS `say` voice and words per minute for the voiceover.
    let voiceName: String?; let voiceRate: Int? }

let args = CommandLine.arguments
let silent = args.contains("--silent")
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
let clipsDir = URL(fileURLWithPath: args[2])
let outURL = URL(fileURLWithPath: args[3])

let size = CGSize(width: 1080, height: 1920)
let crossfade = 0.3
// Tixday's look: white type on deep violet, a concert-pink accent and ticket yellow.
let ink = NSColor.white
let muted = NSColor(white: 1, alpha: 0.75)
let violet = NSColor(srgbRed: 90 / 255, green: 45 / 255, blue: 190 / 255, alpha: 1)
let pink = NSColor(srgbRed: 224 / 255, green: 69 / 255, blue: 123 / 255, alpha: 1)
let yellow = NSColor(srgbRed: 1, green: 216 / 255, blue: 77 / 255, alpha: 1)

// MARK: - Drawing helpers

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    return base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
}

func image(_ size: CGSize, _ draw: (CGContext) -> Void) -> CGImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    draw(context.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    return rep.cgImage!
}

func centered(_ text: String, font: NSFont, color: NSColor) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineHeightMultiple = 0.95
    return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
}

/// Centred text in a box, vertically centred.
func textImage(_ text: NSAttributedString, _ box: CGSize) -> CGImage {
    image(box) { _ in
        let bounds = text.boundingRect(with: box, options: [.usesLineFragmentOrigin])
        text.draw(with: NSRect(x: 0, y: (box.height - bounds.height) / 2, width: box.width, height: bounds.height),
                  options: [.usesLineFragmentOrigin])
    }
}

/// The app icon with rounded corners, for the closing card.
func appIcon() -> CGImage {
    let source = NSImage(contentsOf: root.appending(path: "Tixday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))!
    let side: CGFloat = 360
    return image(CGSize(width: side, height: side)) { _ in
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: side, height: side), xRadius: side * 0.225, yRadius: side * 0.225).addClip()
        source.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
    }
}

/// Deep violet into concert pink with soft rays, like the App Store art.
func backdrop(_ size: CGSize) -> CGImage {
    image(size) { cg in
        NSGradient(colors: [NSColor(srgbRed: 0.10, green: 0.05, blue: 0.24, alpha: 1), violet,
                            NSColor(srgbRed: 0.62, green: 0.18, blue: 0.40, alpha: 1)])!
            .draw(in: NSRect(origin: .zero, size: size), angle: -90)
        let sun = CGPoint(x: size.width / 2, y: -size.height * 0.15)
        cg.setFillColor(NSColor(white: 1, alpha: 0.05).cgColor)
        let rays = 36, step = CGFloat.pi * 2 / CGFloat(rays)
        for index in stride(from: 0, to: rays, by: 2) {
            let a = CGFloat(index) * step
            cg.move(to: sun)
            cg.addLine(to: CGPoint(x: sun.x + cos(a) * 5000, y: sun.y + sin(a) * 5000))
            cg.addLine(to: CGPoint(x: sun.x + cos(a + step) * 5000, y: sun.y + sin(a + step) * 5000))
            cg.closePath()
        }
        cg.fillPath()
    }
}

let brandGradient = NSGradient(colors: [violet, pink])!

/// The pill at the top: "Abonelik Rehberi · Bölüm 1".
func seriesPill() -> CGImage {
    let text = centered(spec.series ?? "", font: roundedFont(34, .bold), color: .white)
    let textSize = text.size()
    let pill = CGSize(width: textSize.width + 56, height: 64)
    return image(pill) { _ in
        brandGradient.draw(in: NSBezierPath(roundedRect: NSRect(origin: .zero, size: pill), xRadius: 32, yRadius: 32), angle: 0)
        text.draw(in: NSRect(x: 0, y: (pill.height - textSize.height) / 2, width: pill.width, height: textSize.height))
    }
}

/// Gradient circle with the step number (or a star for the bonus step).
func badgeImage(_ label: String) -> CGImage {
    let side: CGFloat = 116
    return image(CGSize(width: side, height: side)) { _ in
        brandGradient.draw(in: NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: side - 8, height: side - 8)), angle: -45)
        NSColor(white: 1, alpha: 0.7).setStroke()
        let rim = NSBezierPath(ovalIn: NSRect(x: 5, y: 5, width: side - 10, height: side - 10))
        rim.lineWidth = 3
        rim.stroke()
        let text = centered(label, font: roundedFont(64, .heavy), color: .white)
        let h = text.size().height
        text.draw(in: NSRect(x: 0, y: (side - h) / 2 - 2, width: side, height: h))
    }
}

// MARK: - iPhone frame (same look as the App Store video)

let screenWidth: CGFloat = 640
var screenHeight: CGFloat = 0
let bezel: CGFloat = 12
let band: CGFloat = 7
var screenRadius: CGFloat { screenWidth * 0.155 }
var bodySize: CGSize { CGSize(width: screenWidth + 2 * (bezel + band), height: screenHeight + 2 * (bezel + band)) }

func phoneFrame() -> CGImage {
    let pad: CGFloat = 6
    let canvas = CGSize(width: bodySize.width + 2 * pad, height: bodySize.height + 2 * pad)
    return image(canvas) { cg in
        let body = CGRect(x: pad, y: pad, width: bodySize.width, height: bodySize.height)
        let outerRadius = screenRadius + bezel + band
        let titanium = NSGradient(colors: [NSColor(white: 0.82, alpha: 1), NSColor(white: 0.66, alpha: 1),
                                           NSColor(white: 0.76, alpha: 1), NSColor(white: 0.62, alpha: 1)])!
        func button(_ x: CGFloat, top: CGFloat, length: CGFloat) {
            let rect = CGRect(x: x, y: body.maxY - top - length, width: 8, height: length)
            titanium.draw(in: NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4), angle: 0)
        }
        button(body.minX - 4, top: bodySize.height * 0.16, length: bodySize.height * 0.045)
        button(body.minX - 4, top: bodySize.height * 0.235, length: bodySize.height * 0.07)
        button(body.minX - 4, top: bodySize.height * 0.32, length: bodySize.height * 0.07)
        button(body.maxX - 4, top: bodySize.height * 0.27, length: bodySize.height * 0.11)
        titanium.draw(in: NSBezierPath(roundedRect: body, xRadius: outerRadius, yRadius: outerRadius), angle: -60)
        NSColor(white: 1, alpha: 0.35).setStroke()
        let rim = NSBezierPath(roundedRect: body.insetBy(dx: 1, dy: 1), xRadius: outerRadius - 1, yRadius: outerRadius - 1)
        rim.lineWidth = 2
        rim.stroke()
        NSColor(white: 0.04, alpha: 1).setFill()
        NSBezierPath(roundedRect: body.insetBy(dx: band, dy: band), xRadius: screenRadius + bezel, yRadius: screenRadius + bezel).fill()
        cg.setBlendMode(.clear)
        let screen = body.insetBy(dx: band + bezel, dy: band + bezel)
        cg.addPath(CGPath(roundedRect: screen, cornerWidth: screenRadius, cornerHeight: screenRadius, transform: nil))
        cg.fillPath()
    }
}

// MARK: - Timeline

let composition = AVMutableComposition()
// Scenes take turns on three tracks; with two, three cuts of one clip on the same track can fail to compose.
let tracks = (0..<3).map { _ in composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)! }
var cursor = 0.0
var sceneStarts: [Double] = []
var sourceSize = CGSize.zero
for (index, scene) in spec.scenes.enumerated() {
    let clip = AVURLAsset(url: clipsDir.appending(path: "\(scene.clip).mp4"))
    let source = try await clip.loadTracks(withMediaType: .video)[0]
    sourceSize = try await source.load(.naturalSize)
    let isLast = index == spec.scenes.count - 1
    let extra = isLast ? spec.closing.seconds : crossfade
    let clipLength = try await clip.load(.duration).seconds
    guard scene.end + extra <= clipLength else {
        print("\(scene.clip).mp4 is \(clipLength) s; scene \(index) needs it to run to \(scene.end + extra) s")
        exit(1)
    }
    let range = CMTimeRange(start: CMTime(seconds: scene.start, preferredTimescale: 600),
                            end: CMTime(seconds: scene.end + extra, preferredTimescale: 600))
    try tracks[index % tracks.count].insertTimeRange(range, of: source, at: CMTime(seconds: cursor, preferredTimescale: 600))
    sceneStarts.append(cursor)
    cursor += scene.end - scene.start
}
let total = cursor + spec.closing.seconds
let closingStart = cursor
let hookEnd = sceneStarts.count > 1 ? sceneStarts[1] : closingStart
screenHeight = (screenWidth * sourceSize.height / sourceSize.width).rounded()

// MARK: - Audio: silence for the whole video plus the spoken lines

let tempDir = FileManager.default.temporaryDirectory.appending(path: "tixday-tutorial")
try? FileManager.default.removeItem(at: tempDir)
try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
let silenceURL = tempDir.appending(path: "silence.caf")
do {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    let file = try AVAudioFile(forWriting: silenceURL, settings: format.settings)
    let frames = AVAudioFrameCount(44_100 * (total + 1))
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
    buffer.frameLength = frames
    try file.write(from: buffer)
}
let silenceTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
try silenceTrack.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: total, preferredTimescale: 600)),
                                 of: try await AVURLAsset(url: silenceURL).loadTracks(withMediaType: .audio)[0], at: .zero)

if !silent {
    let voiceTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    // (start time, text, time available before the next line)
    var lines: [(Double, String, Double)] = []
    for (index, scene) in spec.scenes.enumerated() {
        guard let text = scene.voice else { continue }
        let start = sceneStarts[index] + (index == 0 ? 0.3 : 0.15)
        let next = index + 1 < spec.scenes.count ? sceneStarts[index + 1] : closingStart
        lines.append((start, text, next - start + 0.2))
    }
    if let text = spec.closing.voice { lines.append((closingStart + 0.4, text, spec.closing.seconds - 0.4)) }
    for (number, (start, text, room)) in lines.enumerated() {
        let url = tempDir.appending(path: "line\(number).aiff")
        let say = Process()
        say.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        say.arguments = ["-v", spec.voiceName ?? "Samantha", "-r", String(spec.voiceRate ?? 185), "-o", url.path, text]
        try say.run()
        say.waitUntilExit()
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        if duration > room { print(String(format: "warning: line %d is %.1f s but has %.1f s: %@", number, duration, room, text)) }
        let track = try await asset.loadTracks(withMediaType: .audio)[0]
        let length = min(duration, total - start)
        try voiceTrack.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: length, preferredTimescale: 600)),
                                       of: track, at: CMTime(seconds: start, preferredTimescale: 600))
    }
}

// MARK: - Animation helpers

func keyframes(_ keyPath: String, _ frames: [(Double, Any)], easing: CAMediaTimingFunctionName = .easeInEaseOut) -> CAKeyframeAnimation {
    var frames = frames.sorted { $0.0 < $1.0 }
    if frames.first!.0 > 0 { frames.insert((0, frames.first!.1), at: 0) }
    if frames.last!.0 < total { frames.append((total, frames.last!.1)) }
    let animation = CAKeyframeAnimation(keyPath: keyPath)
    animation.values = frames.map(\.1)
    animation.keyTimes = frames.map { NSNumber(value: $0.0 / total) }
    animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: easing), count: frames.count - 1)
    animation.duration = total
    animation.beginTime = AVCoreAnimationBeginTimeAtZero
    animation.isRemovedOnCompletion = false
    animation.fillMode = .both
    return animation
}

func transform(scale: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0) -> NSValue {
    var t = CATransform3DIdentity
    t = CATransform3DTranslate(t, dx, dy, 0)
    t = CATransform3DScale(t, scale, scale, 1)
    return NSValue(caTransform3D: t)
}

/// Visible from `start` to `end` with short fades.
func showBetween(_ layer: CALayer, _ start: Double, _ end: Double, fade: Double = 0.25) {
    layer.opacity = 0
    layer.add(keyframes("opacity", [(max(0, start - 0.01), 0.0), (start, 0.0), (start + fade, 1.0), (end - fade, 1.0), (end, 0.0)]), forKey: "show")
}

// MARK: - Layers (bottom-left origin)

let parent = CALayer()
parent.frame = CGRect(origin: .zero, size: size)

let background = CALayer()
background.bounds = CGRect(x: 0, y: 0, width: size.width * 1.15, height: size.height * 1.15)
background.position = CGPoint(x: size.width / 2, y: size.height / 2)
background.contents = backdrop(background.bounds.size)
background.add(keyframes("position", [(0, NSValue(point: NSPoint(x: size.width / 2 - 50, y: size.height / 2 + 60))),
                                      (total, NSValue(point: NSPoint(x: size.width / 2 + 50, y: size.height / 2 - 60)))],
                         easing: .linear), forKey: "drift")
parent.addSublayer(background)

// The phone with the recording.
let phoneCenter = CGPoint(x: size.width / 2, y: 40 + bodySize.height / 2)
let headerBottom = phoneCenter.y + bodySize.height / 2 + 24
// The phone lives in a stage below the caption: zooms are cropped there (with a soft top edge)
// instead of covering the step text.
let stage = CALayer()
stage.frame = CGRect(x: 0, y: 0, width: size.width, height: headerBottom - 4)
stage.masksToBounds = true
let stageMask = CAGradientLayer()
stageMask.frame = stage.bounds
stageMask.colors = [NSColor.black.cgColor, NSColor.black.cgColor, NSColor.clear.cgColor]
stageMask.locations = [0, NSNumber(value: Double((stage.bounds.height - 70) / stage.bounds.height)), 1]
stageMask.startPoint = CGPoint(x: 0.5, y: 0)
stageMask.endPoint = CGPoint(x: 0.5, y: 1)
stage.mask = stageMask
let phone = CALayer()
phone.bounds = CGRect(origin: .zero, size: bodySize)
phone.position = phoneCenter

let shadow = CALayer()
shadow.frame = phone.bounds.insetBy(dx: 30, dy: 30)
shadow.backgroundColor = NSColor.black.cgColor
shadow.cornerRadius = screenRadius + 20
shadow.shadowColor = violet.cgColor
shadow.shadowOpacity = 0.4
shadow.shadowRadius = 46
shadow.shadowOffset = CGSize(width: 0, height: -30)
phone.addSublayer(shadow)

let display = CALayer()
display.frame = CGRect(x: bezel + band, y: bezel + band, width: screenWidth, height: screenHeight)
display.cornerRadius = screenRadius
display.masksToBounds = true
display.backgroundColor = NSColor.black.cgColor
let videoLayer = CALayer()
videoLayer.frame = display.bounds
display.addSublayer(videoLayer)
phone.addSublayer(display)

let frameLayer = CALayer()
frameLayer.frame = phone.bounds.insetBy(dx: -6, dy: -6)
frameLayer.contents = phoneFrame()
phone.addSublayer(frameLayer)

/// A point of the display (fractions, top-left origin) in the phone layer's coordinates.
func displayPoint(_ x: Double, _ y: Double) -> CGPoint {
    CGPoint(x: display.frame.minX + CGFloat(x) * screenWidth, y: display.frame.maxY - CGFloat(y) * screenHeight)
}

// Tap rings ride on the phone, so they follow its zooms.
for (index, scene) in spec.scenes.enumerated() {
    for tap in scene.taps ?? [] {
        let t = sceneStarts[index] + tap.at
        let point = displayPoint(tap.x, tap.y)
        let ring = CALayer()
        ring.bounds = CGRect(x: 0, y: 0, width: 96, height: 96)
        ring.position = point
        ring.cornerRadius = 48
        ring.borderWidth = 7
        ring.borderColor = NSColor.white.cgColor
        ring.backgroundColor = violet.withAlphaComponent(0.35).cgColor
        ring.shadowColor = violet.cgColor
        ring.shadowOpacity = 0.9
        ring.shadowRadius = 10
        ring.opacity = 0
        ring.add(keyframes("opacity", [(t - 0.01, 0.0), (t, 1.0), (t + 0.45, 0.9), (t + 0.75, 0.0)]), forKey: "show")
        ring.add(keyframes("transform", [(t, transform(scale: 0.45)), (t + 0.25, transform(scale: 0.85)), (t + 0.75, transform(scale: 1.35))],
                           easing: .easeOut), forKey: "pulse")
        phone.addSublayer(ring)
    }
}
stage.addSublayer(phone)
parent.addSublayer(stage)

func focus(_ x: Double, _ y: Double, scale: Double) -> (CGFloat, CGFloat) {
    let p = displayPoint(x, y)
    let px = p.x - bodySize.width / 2, py = p.y - bodySize.height / 2
    return (CGFloat(1 - scale) * px, CGFloat(1 - scale) * py)
}

var phoneFrames: [(Double, Any)] = [(hookEnd - 0.3, transform(scale: 0.9, dy: -60)), (hookEnd + 0.4, transform())]
for (index, scene) in spec.scenes.enumerated() {
    guard let zoom = scene.zoom else { continue }
    let start = sceneStarts[index]
    let (dx, dy) = focus(zoom.x, zoom.y, scale: zoom.scale)
    let lift: CGFloat = 0
    phoneFrames += [(start + zoom.at, transform()),
                    (start + zoom.at + 0.5, transform(scale: CGFloat(zoom.scale), dx: dx, dy: dy + lift)),
                    (start + zoom.until, transform(scale: CGFloat(zoom.scale), dx: dx, dy: dy + lift)),
                    (start + zoom.until + 0.45, transform())]
}
phoneFrames += [(closingStart, transform()), (closingStart + 0.5, transform(scale: 0.85, dy: -700))]
phone.add(keyframes("transform", phoneFrames), forKey: "camera")
phone.add(keyframes("opacity", [(hookEnd - 0.3, 0.0), (hookEnd + 0.2, 1.0), (closingStart + 0.1, 1.0), (closingStart + 0.5, 0.0)]), forKey: "fade")

// Header above the phone: series pill, step badge and caption.
let pill = CALayer()
let pillImage = seriesPill()
pill.bounds = CGRect(x: 0, y: 0, width: pillImage.width, height: pillImage.height)
pill.position = CGPoint(x: size.width / 2, y: size.height - 70)
pill.contents = pillImage
showBetween(pill, 0, closingStart + 0.3)
if spec.series != nil { parent.addSublayer(pill) }

let captionBox = CGRect(x: 170, y: headerBottom, width: size.width - 210, height: size.height - 130 - headerBottom)
for (index, scene) in spec.scenes.enumerated() {
    guard let badge = scene.badge, let caption = scene.caption else { continue }
    let start = sceneStarts[index] + 0.05
    let end = index + 1 < spec.scenes.count ? sceneStarts[index + 1] : closingStart

    let badgeLayer = CALayer()
    badgeLayer.bounds = CGRect(x: 0, y: 0, width: 116, height: 116)
    badgeLayer.position = CGPoint(x: 100, y: captionBox.midY)
    badgeLayer.contents = badgeImage(badge)
    showBetween(badgeLayer, start, end)
    badgeLayer.add(keyframes("transform", [(start, transform(scale: 0.3)), (start + 0.3, transform(scale: 1.12)), (start + 0.45, transform())]), forKey: "pop")
    parent.addSublayer(badgeLayer)

    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 0.95
    let text = NSAttributedString(string: caption, attributes: [.font: roundedFont(70, .heavy), .foregroundColor: ink, .paragraphStyle: style])
    let captionLayer = CALayer()
    captionLayer.frame = captionBox
    captionLayer.contents = image(captionBox.size) { _ in
        let bounds = text.boundingRect(with: captionBox.size, options: [.usesLineFragmentOrigin])
        text.draw(with: NSRect(x: 0, y: (captionBox.height - bounds.height) / 2, width: captionBox.width, height: bounds.height),
                  options: [.usesLineFragmentOrigin])
    }
    showBetween(captionLayer, start, end)
    captionLayer.add(keyframes("transform", [(start, transform(dx: 40)), (start + 0.35, transform())], easing: .easeOut), forKey: "slide")
    parent.addSublayer(captionLayer)
}

// Hook card over the first scene: the promise in big type.
let hookCard = CALayer()
hookCard.frame = parent.frame
hookCard.contents = backdrop(size)
let hookTitle = CALayer()
hookTitle.frame = CGRect(x: 60, y: 820, width: size.width - 120, height: 520)
hookTitle.contents = textImage(centered(spec.hook.title, font: roundedFont(104, .heavy), color: ink), hookTitle.frame.size)
hookCard.addSublayer(hookTitle)
let hookSubtitle = CALayer()
hookSubtitle.frame = CGRect(x: 60, y: 660, width: size.width - 120, height: 150)
hookSubtitle.contents = textImage(centered(spec.hook.subtitle, font: roundedFont(58, .bold), color: yellow), hookSubtitle.frame.size)
hookCard.addSublayer(hookSubtitle)
hookTitle.add(keyframes("transform", [(0, transform(scale: 0.85)), (0.35, transform(scale: 1.04)), (0.5, transform())]), forKey: "pop")
hookSubtitle.opacity = 0
hookSubtitle.add(keyframes("opacity", [(0.5, 0.0), (0.8, 1.0)]), forKey: "show")
hookCard.add(keyframes("opacity", [(0, 1.0), (hookEnd - 0.3, 1.0), (hookEnd + 0.1, 0.0)]), forKey: "fade")
parent.addSublayer(hookCard)
// The pill stays above the hook card.
if spec.series != nil {
    pill.removeFromSuperlayer()
    parent.addSublayer(pill)
}

// Closing: the flower, the name and where to get it.
let closingBackground = CALayer()
closingBackground.frame = parent.frame
closingBackground.contents = backdrop(size)
closingBackground.opacity = 0
closingBackground.add(keyframes("opacity", [(closingStart + 0.15, 0), (closingStart + 0.55, 1)]), forKey: "fade")
parent.addSublayer(closingBackground)

let logo = CALayer()
logo.bounds = CGRect(x: 0, y: 0, width: 360, height: 360)
logo.position = CGPoint(x: size.width / 2, y: 1170)
logo.contents = appIcon()
logo.opacity = 0
logo.add(keyframes("opacity", [(closingStart + 0.3, 0), (closingStart + 0.5, 1)]), forKey: "fade")
logo.add(keyframes("transform", [(closingStart + 0.3, transform(scale: 0.3)), (closingStart + 0.75, transform(scale: 1.12)),
                                 (closingStart + 0.95, transform(scale: 0.96)), (closingStart + 1.1, transform())]), forKey: "spring")
parent.addSublayer(logo)

for (text, font, color, y, delay) in [(spec.closing.title, roundedFont(120, .heavy), ink, 860.0, 0.6),
                                      (spec.closing.subtitle, roundedFont(50, .bold), yellow, 760.0, 0.8)] {
    let line = centered(text, font: font, color: color)
    let layer = CALayer()
    layer.frame = CGRect(x: 0, y: y, width: size.width, height: font.pointSize * 1.4)
    layer.contents = image(layer.frame.size) { _ in
        line.draw(with: NSRect(origin: .zero, size: layer.frame.size), options: [.usesLineFragmentOrigin])
    }
    layer.opacity = 0
    layer.add(keyframes("opacity", [(closingStart + delay, 0), (closingStart + delay + 0.35, 1)]), forKey: "fade")
    layer.add(keyframes("transform", [(closingStart + delay, transform(dy: -40)), (closingStart + delay + 0.45, transform())],
                        easing: .easeOut), forKey: "rise")
    parent.addSublayer(layer)
}

// MARK: - Render

let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = size
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
let fit = CGAffineTransform(scaleX: size.width / sourceSize.width, y: size.height / sourceSize.height)
func instruction(_ start: Double, _ end: Double, _ layers: [AVMutableVideoCompositionLayerInstruction]) -> AVMutableVideoCompositionInstruction {
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), end: CMTime(seconds: end, preferredTimescale: 600))
    instruction.layerInstructions = layers
    return instruction
}
var instructions: [AVMutableVideoCompositionInstruction] = []
for index in spec.scenes.indices {
    let start = sceneStarts[index]
    let end = index + 1 < spec.scenes.count ? sceneStarts[index + 1] : total
    let current = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[index % tracks.count])
    current.setTransform(fit, at: .zero)
    if index + 1 < spec.scenes.count {
        instructions.append(instruction(index == 0 ? 0 : start + crossfade, end, [current]))
        let outgoing = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[index % tracks.count])
        outgoing.setTransform(fit, at: .zero)
        outgoing.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0,
                                timeRange: CMTimeRange(start: CMTime(seconds: end, preferredTimescale: 600),
                                                       duration: CMTime(seconds: crossfade, preferredTimescale: 600)))
        let incoming = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[(index + 1) % tracks.count])
        incoming.setTransform(fit, at: .zero)
        instructions.append(instruction(end, end + crossfade, [outgoing, incoming]))
    } else {
        instructions.append(instruction(start + crossfade, total, [current]))
    }
}
videoComposition.instructions = instructions
videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

try? FileManager.default.removeItem(at: outURL)
let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
export.videoComposition = videoComposition
export.outputURL = outURL
export.outputFileType = .mp4
await export.export()
if export.status != .completed { print("export failed: \(String(describing: export.error))"); exit(1) }
print("wrote \(outURL.path) (\(String(format: "%.1f", total)) s\(silent ? ", silent" : ""))")
