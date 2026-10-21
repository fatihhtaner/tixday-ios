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
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var repeatsYearly = false
    /// Once the user flips the switch, changing the kind no longer sets it.
    @State private var didChooseRepeat = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    /// The picked photo before framing; kept while editing so it can be reframed without losing edges.
    @State private var photoOriginal: UIImage?
    @State private var croppingImage: CroppingImage?

    /// The date the ticket counts to: for a yearly ticket, its next anniversary.
    private var countdownDate: Date {
        repeatsYearly ? DayCount.nextOccurrence(of: date) : date
    }

    private var preview: TicketSnapshot {
        TicketSnapshot(
            title: title.isEmpty ? kind.name : title,
            date: countdownDate,
            kind: kind,
            headline: headline,
            origin: origin.uppercased(),
            destination: destination.uppercased(),
            stubLeft: stubLeft,
            stubRight: stubRight,
            createdAt: event?.createdAt ?? .now,
            repeatsYearly: repeatsYearly,
            // Without Pro a newly picked photo previews (try before you buy), but a stored one stays hidden.
            photoData: pro.isPro || photoData != event?.photoData ? photoData : nil
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
                        // Side by side normally; stacked with large text so the date picker has room.
                        stackable {
                            VStack(alignment: .leading, spacing: 4) {
                                label("Date")
                                Text(Calendar.current.startOfDay(for: countdownDate), format: .relative(presentation: .named, unitsStyle: .wide))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if !typeSize.isAccessibilitySize { Spacer() }
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.vertical, 6)
                        divider
                        Toggle(isOn: Binding(get: { repeatsYearly }, set: { repeatsYearly = $0; didChooseRepeat = true })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Repeats every year")
                                    .font(.subheadline.weight(.semibold))
                                Text("After the day, it counts down to the next one.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.green)
                        .padding(.vertical, 6)
                        divider
                        field(LocalizedStringKey(kind.headlinePrompt)) { TextField("", text: $headline, prompt: Text(kind.headlinePrompt)) }
                    }

                    if kind.showsRoute {
                        card {
                            stackable(spacing: 12) {
                                field("From") {
                                    TextField("", text: $origin, prompt: kind == .flight ? Text(verbatim: "IST") : Text("HOME"))
                                        .textInputAutocapitalization(.characters)
                                }
                                Image(systemName: kind == .flight ? "airplane" : "arrow.right")
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                field("To") {
                                    TextField("", text: $destination, prompt: kind == .flight ? Text(verbatim: "LHR") : Text("NORTH POLE"))
                                        .textInputAutocapitalization(.characters)
                                }
                            }
                        }
                    }

                    card {
                        stackable(spacing: 12) {
                            field("Small print") { TextField("", text: $stubLeft, prompt: Text(kind.stubLeftPrompt)) }
                            field("", spoken: LocalizedStringKey(kind.stubRightPrompt)) { TextField("", text: $stubRight, prompt: Text(kind.stubRightPrompt)) }
                                .frame(width: typeSize.isAccessibilitySize ? nil : 96)
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
            .onAppear {
                load()
                suggestRepeat(for: kind)
            }
            .onChange(of: kind) { _, newKind in suggestRepeat(for: newKind) }
            #if DEBUG
            .task {
                // Tutorial video: name a Tokyo trip, set its date and route, save.
                guard event == nil, DemoMode.createsTicket else { return }
                try? await Task.sleep(for: .seconds(1.2))
                for character in "Tokyo trip" {
                    title.append(character)
                    try? await Task.sleep(for: .seconds(0.11))
                }
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(.snappy) {
                    date = Calendar.current.date(byAdding: .day, value: 45, to: .now) ?? date
                }
                try? await Task.sleep(for: .seconds(0.9))
                for character in "IST" {
                    origin.append(character)
                    try? await Task.sleep(for: .seconds(0.14))
                }
                for character in "HND" {
                    destination.append(character)
                    try? await Task.sleep(for: .seconds(0.14))
                }
                try? await Task.sleep(for: .seconds(1.4))
                save()
            }
            #endif
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason).appLanguage()
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
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(.white)
                            .padding(8)
                            // The tile is a fixed-size poster thumbnail; its label can't grow past it.
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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
                    .accessibilityLabel(Text(verbatim: option.name))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(8)
        }
        .padding(.horizontal, -8)
    }

    /// Your own photo instead of the poster.
    private var photoCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                let row = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 14))
                row {
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
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(photoData == nil ? "Use your own photo" : "Your photo")
                            .font(.body.weight(.semibold))
                        Text(photoData == nil ? "Replaces the poster on the ticket and widget" : "Shown on the ticket and widget")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 4) }
                    if photoData == nil {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            pill("Choose", systemImage: nil)
                        }
                    }
                }
                // With a photo: frame it again, pick another, or go back to the poster.
                if photoData != nil {
                    let buttons = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                    buttons {
                        Button {
                            if let image = photoOriginal ?? photoData.flatMap(UIImage.init(data:)) {
                                croppingImage = CroppingImage(image: image)
                            }
                        } label: {
                            pill("Adjust", systemImage: "crop")
                        }
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            pill("Change", systemImage: "photo")
                        }
                        Button {
                            withAnimation(.snappy) {
                                photoData = nil
                                photoItem = nil
                                photoOriginal = nil
                            }
                        } label: {
                            pill("Remove", systemImage: "xmark")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            isLoadingPhoto = true
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                let image = data.flatMap(PhotoPreparer.workingCopy)
                await MainActor.run {
                    isLoadingPhoto = false
                    // Frame it first; nothing changes until the user taps Done.
                    if let image { croppingImage = CroppingImage(image: image) }
                    photoItem = nil
                }
            }
        }
        .sheet(item: $croppingImage) { item in
            PhotoCropView(image: item.image) { data in
                photoOriginal = item.image
                withAnimation(.snappy) { photoData = data }
            }
            .appLanguage()
        }
    }

    /// A row that turns into a column at accessibility text sizes.
    private func stackable<Content: View>(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing ?? 8))
            : AnyLayout(HStackLayout(spacing: spacing))
        return layout(content)
    }

    private func pill(_ title: LocalizedStringKey, systemImage: String?) -> some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.16), in: Capsule())
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// A caption over an input. `spoken` names the input for VoiceOver when the caption is empty.
    private func field<Content: View>(_ title: LocalizedStringKey, spoken: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label(title)
                .accessibilityHidden(true)
            content()
                .font(.body.weight(.medium))
                // The visible caption above names the field for VoiceOver too.
                .accessibilityLabel(Text(spoken ?? title))
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
        repeatsYearly = event.repeatsYearly
        didChooseRepeat = true
    }

    /// Birthdays and holidays come back every year, so new tickets of those kinds repeat by default.
    private func suggestRepeat(for kind: TicketKind) {
        guard event == nil, !didChooseRepeat else { return }
        repeatsYearly = kind == .birthday || kind == .holiday
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
        target.repeatsYearly = repeatsYearly
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

/// A photo waiting to be framed, as a sheet item.
struct CroppingImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Shrinks a picked photo so it stays light in the store and within the widget's memory limit.
enum PhotoPreparer {
    static let maxSide: CGFloat = 1200

    /// The picked photo, upright and at most 2400 px, for framing.
    static func workingCopy(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, 2400 / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// The framed part of a photo (rect in the image's points), at most `maxSide` wide, as JPEG.
    static func crop(_ image: UIImage, to rect: CGRect) -> Data? {
        let scale = min(1, maxSide / rect.width)
        let size = CGSize(width: (rect.width * scale).rounded(), height: (rect.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let cropped = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(x: -rect.minX * scale, y: -rect.minY * scale,
                                  width: image.size.width * scale, height: image.size.height * scale))
        }
        return cropped.jpegData(compressionQuality: 0.82)
    }
}
