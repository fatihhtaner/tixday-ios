import SwiftData
import SwiftUI
import WidgetKit

/// One ticket up close: a live clock to the day, and edit / share / delete.
struct TicketDetailView: View {
    let event: TicketEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    private var style: TicketStyle { event.kind.style }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                TicketView(ticket: event.snapshot, size: .medium, notchColor: nil)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .ticketShadow()
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    LiveCountdown(target: event.date, style: style)
                    Text("Until the day begins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(event.date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(event.kind.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    actionButton("Edit", systemImage: "pencil") { isEditing = true }
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview(event.title, image: shareImage)
                    ) {
                        actionLabel("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PressableStyle())
                    actionButton("Delete", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background {
            ZStack {
                Theme.canvas
                RadialGradient(colors: [style.background.opacity(0.95), style.background.opacity(0)], center: .top, startRadius: 20, endRadius: 560)
            }
            .ignoresSafeArea()
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            EventEditorView(event: event)
        }
        .confirmationDialog("Delete this ticket?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(event)
                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
                dismiss()
            }
        }
    }

    /// The ticket as a picture, for sharing.
    @MainActor
    private var shareImage: Image {
        let renderer = ImageRenderer(
            content: TicketView(ticket: event.snapshot, size: .medium, notchColor: nil)
                .frame(width: 360, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(20)
        )
        renderer.scale = 3
        return Image(uiImage: renderer.uiImage ?? UIImage())
    }

    private func actionButton(_ title: LocalizedStringKey, systemImage: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            actionLabel(title, systemImage: systemImage, isDestructive: role == .destructive)
        }
        .buttonStyle(PressableStyle())
    }

    private func actionLabel(_ title: LocalizedStringKey, systemImage: String, isDestructive: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(height: 24)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(isDestructive ? Color.red : Theme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
    }
}

/// Days, hours, minutes and seconds to the start of the day, ticking every second.
private struct LiveCountdown: View {
    var target: Date
    var style: TicketStyle

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let parts = components(now: context.date)
            HStack(spacing: 10) {
                tile(parts.days, "DAYS")
                tile(parts.hours, "HRS")
                tile(parts.minutes, "MIN")
                tile(parts.seconds, "SEC")
            }
        }
    }

    private func components(now: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let start = Calendar.current.startOfDay(for: target)
        let remaining = max(Int(start.timeIntervalSince(now)), 0)
        return (remaining / 86_400, remaining % 86_400 / 3_600, remaining % 3_600 / 60, remaining % 60)
    }

    private func tile(_ value: Int, _ unit: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value, format: .number)
                .font(.system(size: 30, weight: .bold, design: style.design).width(style.numberWidth))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Theme.ink)
            Text(unit)
                .font(.system(size: 10, weight: .semibold).width(.expanded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.snappy, value: value)
    }
}
