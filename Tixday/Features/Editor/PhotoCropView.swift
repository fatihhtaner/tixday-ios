import SwiftUI
import UIKit

/// Lets the user frame their photo before it goes on the ticket: drag to move, pinch to zoom.
/// The frame has the ticket's shape; the dashed square is what the small widget shows.
/// The chosen framing is cropped into the saved photo, so every ticket and widget shows it centred.
struct PhotoCropView: View {
    let image: UIImage
    var onDone: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    /// Width ÷ height of the frame, close to the big ticket and the medium widget.
    static let aspect: CGFloat = 1.6
    private static let maxScale: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("Adjust photo").font(.headline)
                Spacer()
                Button("Done") { finish() }
                    .font(.body.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .frame(height: 56)

            GeometryReader { proxy in
                let frame = frameSize(in: proxy.size)
                let base = baseScale(for: frame)
                let current = clampedScale(scale * pinch)
                let shown = clampedOffset(CGSize(width: offset.width + drag.width, height: offset.height + drag.height),
                                          frame: frame, scale: base * current)
                // The photo sits in an overlay, so its size never pushes the layout around.
                // A shape, not Color: Color would stretch into the safe area and push the header up.
                Rectangle()
                    .fill(.black)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: image.size.width * base * current, height: image.size.height * base * current)
                            .offset(shown)
                    }
                    .clipped()
                    .overlay {
                        ZStack {
                            // Dims everything outside the ticket frame.
                            Canvas { context, size in
                                context.fill(FrameCutout(frame: frame, cornerRadius: 28).path(in: CGRect(origin: .zero, size: size)),
                                             with: .color(.black.opacity(0.7)), style: FillStyle(eoFill: true))
                            }
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(.white, lineWidth: 2)
                                .frame(width: frame.width, height: frame.height)
                            // The part the small, square widget shows.
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                                .frame(width: frame.height, height: frame.height)
                        }
                        .allowsHitTesting(false)
                    }
                .onAppear { lastFrame = frame }
                .onChange(of: proxy.size) { _, size in lastFrame = frameSize(in: size) }
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        DragGesture().updating($drag) { value, state, _ in state = value.translation },
                        MagnifyGesture().updating($pinch) { value, state, _ in state = value.magnification }
                    )
                    .onEnded { value in
                        let newScale = clampedScale(scale * (value.second?.magnification ?? 1))
                        let moved = value.first?.translation ?? .zero
                        scale = newScale
                        offset = clampedOffset(CGSize(width: offset.width + moved.width, height: offset.height + moved.height),
                                               frame: frame, scale: base * newScale)
                    }
                )
            }

            VStack(spacing: 4) {
                Label("Drag to move, pinch to zoom", systemImage: "hand.draw")
                    .font(.subheadline.weight(.semibold))
                Text("The dashed square is what the small widget shows.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color.black)
        // Dragging the photo must not pull the sheet down.
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .environment(\.colorScheme, .dark)
        .tint(.white)
    }

    // MARK: - Geometry

    private func frameSize(in size: CGSize) -> CGSize {
        let width = min(size.width - 40, (size.height - 40) * Self.aspect)
        return CGSize(width: width, height: width / Self.aspect)
    }

    /// The scale at which the photo just covers the frame.
    private func baseScale(for frame: CGSize) -> CGFloat {
        max(frame.width / image.size.width, frame.height / image.size.height)
    }

    private func clampedScale(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), Self.maxScale)
    }

    /// Keeps the photo covering the whole frame.
    private func clampedOffset(_ value: CGSize, frame: CGSize, scale: CGFloat) -> CGSize {
        let maxX = max((image.size.width * scale - frame.width) / 2, 0)
        let maxY = max((image.size.height * scale - frame.height) / 2, 0)
        return CGSize(width: min(max(value.width, -maxX), maxX), height: min(max(value.height, -maxY), maxY))
    }

    // MARK: - Output

    private func finish() {
        // Work in a reference frame; the crop is the same at any frame size.
        let frame = CGSize(width: 1000, height: 1000 / Self.aspect)
        let screenFrame = lastFrame
        let ratio = frame.width / screenFrame.width
        let base = baseScale(for: frame)
        let total = base * scale
        let shown = clampedOffset(CGSize(width: offset.width * ratio, height: offset.height * ratio), frame: frame, scale: total)
        // The frame's top-left corner in photo points.
        let origin = CGPoint(
            x: (image.size.width * total - frame.width) / 2 - shown.width,
            y: (image.size.height * total - frame.height) / 2 - shown.height
        )
        let crop = CGRect(x: origin.x / total, y: origin.y / total, width: frame.width / total, height: frame.height / total)
        if let data = PhotoPreparer.crop(image, to: crop) {
            onDone(data)
        }
        dismiss()
    }

    /// The on-screen frame size, for converting the drag offset (set by the GeometryReader).
    @State private var lastFrame = CGSize(width: 1000, height: 1000 / aspect)
}

/// The whole area with a rounded hole for the frame, filled even-odd to dim only the outside.
private struct FrameCutout: Shape {
    var frame: CGSize
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let hole = CGRect(x: rect.midX - frame.width / 2, y: rect.midY - frame.height / 2, width: frame.width, height: frame.height)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius), style: .continuous)
        return path
    }
}
