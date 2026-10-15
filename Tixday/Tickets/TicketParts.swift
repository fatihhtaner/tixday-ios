import SwiftUI

/// Words under the big number: "DAYS", "DAY", "TODAY" or "DONE".
enum CountLabel {
    static func text(for days: Int) -> String {
        switch days {
        case ..<0: String(localized: "DONE", bundle: .app)
        case 0: String(localized: "TODAY", bundle: .app)
        default: unit(String(localized: "\(days) DAYS", bundle: .app, comment: "Unit under a day count; the app removes the number and draws it separately"))
        }
    }

    /// Drops the number from a pluralised phrase like "83 DAYS TO GO": the catalog needs it to pick
    /// the right plural form, but the ticket draws the number on its own, larger. Works for any digit script.
    static func unit(_ phrase: String) -> String {
        phrase.filter { !$0.isNumber }
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    /// The number itself; past dates show how long ago they were.
    static func number(for days: Int) -> String {
        "\(abs(days))"
    }
}

extension Date {
    /// "12 JAN" style date for the stub.
    var stubText: String {
        formatted(.dateTime.day().month(.abbreviated).locale(AppLanguage.locale)).uppercased(with: AppLanguage.locale)
    }
}

/// The dashed tear line between a ticket and its stub.
struct Perforation: View {
    enum Axis { case horizontal, vertical }

    var axis: Axis
    var color: Color

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                if axis == .horizontal {
                    path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                } else {
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
        }
        .frame(width: axis == .vertical ? 2 : nil, height: axis == .horizontal ? 2 : nil)
    }
}

/// Half-circle punches at both ends of the tear line.
/// With no colour they are cut out of the ticket, so whatever is behind it shows through.
struct Notches: View {
    var axis: Perforation.Axis
    var color: Color?
    var size: CGFloat = 14

    var body: some View {
        if axis == .horizontal {
            HStack {
                punch.offset(x: -size / 2)
                Spacer()
                punch.offset(x: size / 2)
            }
        } else {
            VStack {
                punch.offset(y: -size / 2)
                Spacer()
                punch.offset(y: size / 2)
            }
        }
    }

    private var punch: some View {
        Circle()
            .fill(color ?? .black)
            .frame(width: size, height: size)
            .blendMode(color == nil ? .destinationOut : .normal)
    }
}

/// The rubber stamp a used ticket gets: "ADMITTED", in red, slightly crooked.
/// `isStamped` false hides it, large, so it can land with an animation.
struct AdmittedStamp: View {
    var size: CGFloat = 15
    var isStamped = true

    static let ink = Color(hex: "#E5483B")

    var body: some View {
        Text("ADMITTED")
            .font(.system(size: size, weight: .black).width(.expanded))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Self.ink)
            .padding(.horizontal, size * 0.6)
            .padding(.vertical, size * 0.35)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.35)
                    .strokeBorder(Self.ink, lineWidth: max(size * 0.15, 1.5))
            )
            .padding(size * 0.2)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.5)
                    .strokeBorder(Self.ink.opacity(0.7), lineWidth: max(size * 0.07, 1))
            )
            .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: size * 0.5))
            .rotationEffect(.degrees(-12))
            .scaleEffect(isStamped ? 1 : 2.2)
            .opacity(isStamped ? 0.95 : 0)
            .accessibilityLabel(Text("ADMITTED"))
    }
}

/// How far along the wait is.
struct WaitProgressBar: View {
    var progress: Double
    var track: Color
    var fill: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill).frame(width: max(proxy.size.width * progress, 6))
            }
        }
        .frame(height: 6)
    }
}
