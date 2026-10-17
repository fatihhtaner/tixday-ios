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
                        item: TicketShareCard(ticket: event.snapshot),
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

    /// The ticket as a picture, for the share sheet's preview.
    @MainActor
    private var shareImage: Image {
        Image(uiImage: TicketShareCard(ticket: event.snapshot).image())
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
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        // Three buttons share a row; past this size the labels would break mid-word.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
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
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Side-by-side pieces stack once the text is too large to share a line.
    private var stacks: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        let progress = DayCount.progress(createdAt: ticket.createdAt, target: ticket.date)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ticket.date.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: AppLanguage.locale)))
                        .font(.headline)
                    let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: 3)) : AnyLayout(HStackLayout(spacing: 8))
                    layout {
                        Text(ticket.kind.name)
                        if ticket.repeatsYearly {
                            Label("Every year", systemImage: "repeat")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if !stacks {
                    Image(systemName: ticket.kind.symbol)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                WaitProgressBar(progress: progress, track: .white.opacity(0.18), fill: .white)
                let footer = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout())
                footer {
                    Text("\(Int((progress * 100).rounded()))% of the wait is behind you")
                    if !stacks { Spacer() }
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
