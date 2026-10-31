// Speeds up (or slows down) a recording without changing its pitch, using AVAudioUnitTimePitch offline.
// Used to tighten VoxCPM2 voiceovers for the short videos.
//
// Usage: swift tools/speed_audio.swift <in.wav> <out.wav> <rate>     (e.g. 1.15 = 15% faster)
import AVFoundation

let args = CommandLine.arguments
let input = try AVAudioFile(forReading: URL(fileURLWithPath: args[1]))
let rate = Float(args[3]) ?? 1.0
let format = input.processingFormat

let engine = AVAudioEngine()
let player = AVAudioPlayerNode()
let pitch = AVAudioUnitTimePitch()
pitch.rate = rate
engine.attach(player)
engine.attach(pitch)
engine.connect(player, to: pitch, format: format)
engine.connect(pitch, to: engine.mainMixerNode, format: format)
try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
try engine.start()
player.scheduleFile(input, at: nil)
player.play()

var output: AVAudioFile? = try AVAudioFile(forWriting: URL(fileURLWithPath: args[2]), settings: input.fileFormat.settings)
let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
// Expected output length plus a little tail for the time-pitch unit's latency.
let target = AVAudioFramePosition(Double(input.length) / Double(rate)) + AVAudioFramePosition(format.sampleRate * 0.1)
while engine.manualRenderingSampleTime < target {
    let frames = min(AVAudioFrameCount(target - engine.manualRenderingSampleTime), buffer.frameCapacity)
    guard try engine.renderOffline(frames, to: buffer) == .success else { break }
    try output?.write(from: buffer)
}
engine.stop()
output = nil  // closes the file and finalises its header
print(String(format: "wrote %@ (%.2fx)", args[2], rate))
