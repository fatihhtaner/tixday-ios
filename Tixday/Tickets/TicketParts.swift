import SwiftUI

/// Words under the big number: "DAYS", "DAY", "TODAY" or "DONE".
enum CountLabel {
    static func text(for days: Int) -> String {
        switch days {
        case ..<0: String(localized: "DONE")
        case 0: String(localized: "TODAY")
        default: unit(String(localized: "\(days) DAYS", comment: "Unit under a day count; the app removes the number and draws it separately"))
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
        formatted(.dateTime.day().month(.abbreviated)).uppercased(with: .current)
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
