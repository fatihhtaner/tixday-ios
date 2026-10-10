import SwiftData
import SwiftUI
import WidgetKit

/// One ticket up close, in its poster's atmosphere: the big ticket, how far along the wait is,
/// and edit / share / delete.
struct TicketDetailView: View {
    let event: TicketEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    /// Read so the view redraws when Pro changes (photos show only with Pro).
    @Environment(ProStore.self) private var pro
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    private var style: TicketStyle { event.kind.style }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HeroTicket(ticket: event.snapshot)
                    .padding(.top, 8)

                WaitCard(ticket: event.snapshot)

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
        .scrollIndicators(.hidden)
        .id(pro.isPro)
        .background { PosterBackdrop(kind: event.kind, photo: TicketPhoto.image(event.snapshot.photoData)) }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $isEditing) {
            EventEditorView(event: event).appLanguage()
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
        .foregroundStyle(isDestructive ? Color.red : Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
    }
}

/// The date in full, and how much of the wait is already behind you.
private struct WaitCard: View {
    let ticket: TicketSnapshot

    var body: some View {
        let progress = DayCount.progress(createdAt: ticket.createdAt, target: ticket.date)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ticket.date.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: AppLanguage.locale)))
                        .font(.headline)
                    Text(ticket.kind.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: ticket.kind.symbol)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                WaitProgressBar(progress: progress, track: .white.opacity(0.18), fill: .white)
                HStack {
                    Text("\(Int((progress * 100).rounded()))% of the wait is behind you")
                    Spacer()
                    Text(ticket.createdAt, format: .relative(presentation: .named))
                        .foregroundStyle(.tertiary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
