import SwiftUI

/// Shown in place of the paywall right after a purchase or restore: a gold Pro pass flips in,
/// gets stamped, ticket stubs rain down, and the unlocked features follow.
struct ProWelcomeView: View {
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 hidden, 1 pass in, 2 stamped, 3 text and features in.
    @State private var stage = 0
    @State private var isShowingWidgetHelp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                ProPass(isStamped: stage >= 2, reduceMotion: reduceMotion)
                    .rotation3DEffect(.degrees(stage >= 1 ? 0 : -75), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                    .scaleEffect(stage >= 1 ? 1 : 0.7)
                    .offset(y: stage >= 1 ? 0 : 60)
                    .opacity(stage >= 1 ? 1 : 0)
                    .padding(.top, 56)

                VStack(spacing: 8) {
                    Text("Welcome to Tixday Pro!")
                        .font(Theme.display(26))
                        .multilineTextAlignment(.center)
                    Text("Everything is unlocked. Thanks for supporting an independent app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 ? 0 : 12)

                VStack(alignment: .leading, spacing: 0) {
                    feature("infinity", "Unlimited tickets", "Add every date you're waiting for.", index: 0)
                    feature("photo.on.rectangle.angled", "Your own photos", "Put any photo on a ticket and its widget.", index: 1)
                    Button { isShowingWidgetHelp = true } label: {
                        feature("lock.rectangle.on.rectangle", "Lock Screen widgets", "Tap to see how to add one.", index: 2, showsChevron: true)
                    }
                    .buttonStyle(.plain)
                }
                .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .opacity(stage >= 3 ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text("Let's go")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.white, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .opacity(stage >= 3 ? 1 : 0)
        }
        .overlay {
            if !reduceMotion && stage >= 2 {
                StubShower().allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            CircleIconButton(title: "Close", systemImage: "xmark", action: onDone)
                .padding(12)
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: stage == 2)
        .sensoryFeedback(.success, trigger: stage == 3)
        .task { await play() }
        .sheet(isPresented: $isShowingWidgetHelp) { LockScreenWidgetHelp() }
    }

    private func play() async {
        if reduceMotion {
            stage = 3
            return
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) { stage = 1 }
        try? await Task.sleep(for: .milliseconds(750))
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { stage = 2 }
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeOut(duration: 0.45)) { stage = 3 }
    }

    private func feature(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey, index: Int, showsChevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: showsChevron ? "chevron.right" : "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(showsChevron ? Color.secondary : ProPass.gold)
                .flipsForRightToLeftLayoutDirection(showsChevron)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .offset(x: stage >= 3 ? 0 : 24)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: stage)
    }
}

/// The gold all-access ticket at the top of the welcome screen.
private struct ProPass: View {
    static let gold = Color(hex: "#F2C14E")
    private static let ink = Color(hex: "#3B2A05")

    var isStamped: Bool
    var reduceMotion: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ALL ACCESS")
                    .font(Theme.eyebrow)
                    .tracking(1.5)
                    .opacity(0.7)
                Text(verbatim: "TIXDAY PRO")
                    .font(Theme.display(26))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                Text("Every date, every widget")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.75)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Perforation(axis: .vertical, color: Self.ink.opacity(0.35))
                .padding(.vertical, 14)

            VStack(spacing: 2) {
                Image(systemName: "infinity")
                    .font(.system(size: 30, weight: .black))
                Text("ADMIT")
                    .font(.caption2.weight(.heavy))
                    .tracking(1)
                    .opacity(0.7)
            }
            .frame(width: 92)
        }
        .foregroundStyle(Self.ink)
        .frame(height: 168)
        .background {
            LinearGradient(colors: [Color(hex: "#FBE29A"), Self.gold, Color(hex: "#D99A2B")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay { shine }
        }
        .overlay(alignment: .trailing) {
            Notches(axis: .vertical, color: nil, size: 18)
                .frame(width: 18)
                .padding(.trailing, 92 - 9)
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            // Centred on the stub, below the infinity mark.
            stamp.fixedSize().frame(width: 92).padding(.trailing, 4).padding(.bottom, 20)
        }
        .shadow(color: Self.gold.opacity(0.45), radius: 30, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Tixday Pro"))
    }

    /// A light sweep across the foil, once.
    private var shine: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: proxy.size.width * 0.35)
                .rotationEffect(.degrees(20))
                .offset(x: isStamped && !reduceMotion ? proxy.size.width * 1.2 : -proxy.size.width * 0.5)
                .animation(.easeInOut(duration: 1.1).delay(0.15), value: isStamped)
        }
        .allowsHitTesting(false)
    }

    /// "Admitted" stamp that lands on the stub.
    private var stamp: some View {
        Text("ADMITTED")
            .font(.system(size: 11, weight: .black).width(.expanded))
            .lineLimit(1)
            .foregroundStyle(Color(hex: "#B3261E"))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color(hex: "#B3261E"), lineWidth: 2))
            .rotationEffect(.degrees(-9))
            .scaleEffect(isStamped ? 1 : 2.4)
            .opacity(isStamped ? 0.9 : 0)
    }
}

/// Little ticket stubs in every kind's colour falling once. Driven by the clock so the
/// paywall-to-welcome transition can't swallow it.
private struct StubShower: View {
    private struct Piece: Identifiable {
        let id: Int
        let color: Color
        let x: CGFloat
        let width: CGFloat
        let delay: Double
        let duration: Double
        let spin: Double
        let flip: Double
        let drift: CGFloat
    }

    private static let length = 4.2

    @State private var start = Date.now
    @State private var isFinished = false
    private let pieces: [Piece] = (0..<34).map { index in
        let kinds = TicketKind.allCases
        return Piece(
            id: index,
            color: index.isMultiple(of: 4) ? ProPass.gold : kinds[index % kinds.count].style.stubFill,
            x: .random(in: 0.03...0.97),
            width: .random(in: 14...24),
            delay: .random(in: 0...0.8),
            duration: .random(in: 2.2...3.2),
            spin: .random(in: -300...300),
            flip: .random(in: 1...3),
            drift: .random(in: -36...36)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            if !isFinished {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    ForEach(pieces) { piece in
                        let progress = min(max((elapsed - piece.delay) / piece.duration, 0), 1)
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(piece.color)
                            .overlay(
                                Rectangle()
                                    .fill(.white.opacity(0.5))
                                    .frame(width: 1)
                                    .offset(x: piece.width * 0.22)
                            )
                            .frame(width: piece.width, height: piece.width * 0.55)
                            .rotation3DEffect(.degrees(360 * piece.flip * progress), axis: (x: 1, y: 0.3, z: 0))
                            .rotationEffect(.degrees(piece.spin * progress))
                            .position(
                                x: piece.x * proxy.size.width + piece.drift * sin(progress * .pi * 2),
                                y: -30 + (proxy.size.height + 60) * progress * progress
                            )
                            .opacity(progress > 0.85 ? (1 - progress) / 0.15 : (progress > 0 ? 1 : 0))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .task {
            start = .now
            try? await Task.sleep(for: .seconds(Self.length))
            isFinished = true
        }
    }
}

/// How to put Tixday on the Lock Screen, in three steps.
private struct LockScreenWidgetHelp: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add a Lock Screen widget")
                .font(Theme.display(20))
                .padding(.top, 28)
            step(1, "Touch and hold your Lock Screen, then tap Customize.")
            step(2, "Choose Lock Screen and tap the area under the clock.")
            step(3, "Pick Tixday. Tap the widget again to choose a ticket.")
            Spacer(minLength: 0)
            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationBackground(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 26, height: 26)
                .background(ProPass.gold, in: Circle())
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
