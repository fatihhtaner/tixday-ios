import SwiftUI

extension View {
    /// Liquid Glass on iOS 26; a frosted material before that.
    @ViewBuilder
    func glassBackground<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = tint.map { Glass.regular.tint($0) } ?? .regular
            self.glassEffect(interactive ? glass.interactive() : glass, in: shape)
        } else {
            self.background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint { shape.fill(tint) }
                }
            }
        }
    }

    /// Pins a header above scrolling content. On iOS 26 content fades softly under it; before that
    /// the header sits on a frosted bar.
    @ViewBuilder
    func pinnedTopBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: .top, content: bar)
                .scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self.safeAreaInset(edge: .top, spacing: 0) {
                bar().background(.ultraThinMaterial)
            }
        }
    }

    /// Marks a view as the place a zoom transition grows from (iOS 18+).
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Pushes this screen by zooming out of its source (iOS 18+); a normal push before that.
    @ViewBuilder
    func zoomTransition(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

/// Slight shrink on touch, so tickets feel like physical cards.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// A round glass icon button (close, settings). The circle lives inside the label so the whole
/// circle is tappable, not just the glyph.
struct CircleIconButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var size: CGFloat = 36
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 15, weight: .bold))
                .frame(width: size, height: size)
                .contentShape(Circle())
                .glassBackground(in: Circle(), interactive: true)
                // A larger touch target than the visible circle.
                .padding(4)
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }
}
