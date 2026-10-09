import PhotosUI
import SwiftData
import SwiftUI
import WidgetKit

/// Creates or edits a ticket. The preview on top redraws as the user types.
struct EventEditorView: View {
    var event: TicketEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @State private var paywallReason: ProFeature?

    @State private var kind: TicketKind = .flight
    @State private var title = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var headline = ""
    @State private var origin = ""
    @State private var destination = ""
    @State private var stubLeft = ""
    @State private var stubRight = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

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
            createdAt: event?.createdAt ?? .now,
            photoData: photoData
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    HeroTicket(ticket: preview)
                        .animation(.snappy, value: kind)

                    kindPicker

                    photoCard

                    card {
                        field("Title") { TextField("", text: $title, prompt: Text(kind.name)) }
                        divider
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                label("Date")
                                Text(Calendar.current.startOfDay(for: date), format: .relative(presentation: .named, unitsStyle: .wide))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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
                                Image(systemName: kind == .flight ? "airplane" : "arrow.right")
                                    .foregroundStyle(.secondary)
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
            .scrollIndicators(.hidden)
            .background { PosterBackdrop(kind: kind, photo: TicketPhoto.image(photoData)) }
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
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        // The editor takes on the ticket's atmosphere: its poster, blurred and darkened.
        .environment(\.colorScheme, .dark)
        .tint(.white)
    }

    // MARK: - Pieces

    /// Each kind as a little poster to pick from.
    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TicketKind.allCases) { option in
                    let isSelected = option == kind
                    Button {
                        withAnimation(.snappy) { kind = option }
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            if let poster = TicketPoster.image(option, .square) {
                                // Sized here so the overflow is cropped and doesn't push the label out.
                                poster.resizable().scaledToFill().frame(width: 84, height: 104).clipped()
                            } else {
                                option.style.background
                            }
                            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 2) {
                                Image(systemName: option.symbol)
                                    .font(.system(size: 12, weight: .bold))
                                Text(option.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(.white)
                            .padding(8)
                        }
                        .frame(width: 84, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.white, lineWidth: isSelected ? 2.5 : 0)
                                .padding(-5)
                        )
                        .scaleEffect(isSelected ? 1 : 0.94)
                        .opacity(isSelected ? 1 : 0.75)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(8)
        }
        .padding(.horizontal, -8)
    }

    /// Your own photo instead of the poster.
    private var photoCard: some View {
        card {
            HStack(spacing: 14) {
                Group {
                    if let photo = TicketPhoto.image(photoData) {
                        photo.resizable().scaledToFill()
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white.opacity(0.08))
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { if isLoadingPhoto { ProgressView() } }

                VStack(alignment: .leading, spacing: 2) {
                    Text(photoData == nil ? "Use your own photo" : "Your photo")
                        .font(.body.weight(.semibold))
                    Text(photoData == nil ? "Replaces the poster on the ticket and widget" : "Shown on the ticket and widget")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)

                if photoData != nil {
                    Button("Remove photo", systemImage: "xmark.circle.fill") {
                        withAnimation(.snappy) {
                            photoData = nil
                            photoItem = nil
                        }
                    }
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(photoData == nil ? "Choose" : "Change")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.16), in: Capsule())
                }
            }
            .padding(.vertical, 6)
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            isLoadingPhoto = true
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                let prepared = data.flatMap(PhotoPreparer.prepare)
                await MainActor.run {
                    withAnimation(.snappy) { if let prepared { photoData = prepared } }
                    isLoadingPhoto = false
                }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
        photoData = event.photoData
    }

    private func save() {
        // Anyone can try a photo in the preview; keeping a new one needs Pro.
        if photoData != nil, photoData != event?.photoData, !pro.isPro {
            paywallReason = .photos
            return
        }
        let target = event ?? TicketEvent(title: "", date: date, kind: kind)
        target.kind = kind
        target.title = title.trimmingCharacters(in: .whitespaces).isEmpty ? kind.name : title
        target.date = date
        target.headline = headline
        target.origin = origin.uppercased()
        target.destination = destination.uppercased()
        target.stubLeft = stubLeft
        target.stubRight = stubRight
        target.photoData = photoData
        if event == nil { context.insert(target) }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        // Asks for permission the first time, then plans reminders (the home screen re-plans on later changes).
        let tickets = ((try? context.fetch(FetchDescriptor<TicketEvent>())) ?? []).map(\.snapshot)
        Task {
            await TicketNotifications.requestAuthorizationIfNeeded()
            await TicketNotifications.reschedule(tickets)
        }
        dismiss()
    }
}

/// Shrinks a picked photo so it stays light in the store and within the widget's memory limit.
enum PhotoPreparer {
    static let maxSide: CGFloat = 1200

    static func prepare(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
