import SwiftData
import SwiftUI
import WidgetKit

/// Creates or edits a ticket. The preview on top redraws as the user types.
struct EventEditorView: View {
    var event: TicketEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var kind: TicketKind = .flight
    @State private var title = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var headline = ""
    @State private var origin = ""
    @State private var destination = ""
    @State private var stubLeft = ""
    @State private var stubRight = ""

    private var preview: TicketSnapshot {
        TicketSnapshot(
            title: title.isEmpty ? kind.name : title,
            date: date,
            kind: kind,
            headline: headline,
            origin: origin.uppercased(),
            destination: destination.uppercased(),
            stubLeft: stubLeft,
            stubRight: stubRight,
            createdAt: event?.createdAt ?? .now
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TicketView(ticket: preview, size: .medium, notchColor: nil)
                        .frame(height: 172)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .ticketShadow()
                        .animation(.snappy, value: kind)

                    kindPicker

                    card {
                        field("Title") { TextField("", text: $title, prompt: Text(kind.name)) }
                        divider
                        HStack {
                            label("Date")
                            Spacer()
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.vertical, 6)
                        divider
                        field(LocalizedStringKey(kind.headlinePrompt)) { TextField("", text: $headline, prompt: Text(kind.headlinePrompt)) }
                    }

                    if kind.showsRoute {
                        card {
                            HStack(spacing: 12) {
                                field("From") {
                                    TextField("", text: $origin, prompt: Text(kind == .flight ? "IST" : "HOME"))
                                        .textInputAutocapitalization(.characters)
                                }
                                Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                                field("To") {
                                    TextField("", text: $destination, prompt: Text(kind == .flight ? "HND" : "NORTH POLE"))
                                        .textInputAutocapitalization(.characters)
                                }
                            }
                        }
                    }

                    card {
                        HStack(spacing: 12) {
                            field("Small print") { TextField("", text: $stubLeft, prompt: Text(kind.stubLeftPrompt)) }
                            field("") { TextField("", text: $stubRight, prompt: Text(kind.stubRightPrompt)) }
                                .frame(width: 96)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background {
                ZStack {
                    Theme.canvas
                    LinearGradient(colors: [kind.style.background.opacity(0.6), .clear], startPoint: .top, endPoint: .center)
                        .animation(.easeInOut, value: kind)
                }
                .ignoresSafeArea()
            }
            .navigationTitle(event == nil ? "New ticket" : "Edit ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
        .tint(Theme.ink)
    }

    // MARK: - Pieces

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TicketKind.allCases) { option in
                    let isSelected = option == kind
                    Button {
                        withAnimation(.snappy) { kind = option }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(option.style.ink)
                                .frame(width: 62, height: 62)
                                .background(option.style.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Theme.ink.opacity(0.08), lineWidth: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Theme.ink, lineWidth: isSelected ? 2 : 0)
                                        .padding(-4)
                                )
                            Text(option.name)
                                .font(.caption.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? Theme.ink : .secondary)
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(6)
        }
        .padding(.horizontal, -6)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func field<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label(title)
            content()
                .font(.body.weight(.medium))
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .textCase(.uppercase)
            .font(.system(size: 11, weight: .semibold).width(.expanded))
            .foregroundStyle(.secondary)
    }

    private var divider: some View {
        Divider().padding(.vertical, 2)
    }

    // MARK: - Data

    private func load() {
        guard let event else { return }
        kind = event.kind
        title = event.title
        date = event.date
        headline = event.headline
        origin = event.origin
        destination = event.destination
        stubLeft = event.stubLeft
        stubRight = event.stubRight
    }

    private func save() {
        let target = event ?? TicketEvent(title: "", date: date, kind: kind)
        target.kind = kind
        target.title = title.trimmingCharacters(in: .whitespaces).isEmpty ? kind.name : title
        target.date = date
        target.headline = headline
        target.origin = origin.uppercased()
        target.destination = destination.uppercased()
        target.stubLeft = stubLeft
        target.stubRight = stubRight
        if event == nil { context.insert(target) }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
