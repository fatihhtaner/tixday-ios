import SwiftUI
import WidgetKit

/// The app's language: the iPhone's own, or any language Tixday is translated into.
/// Applies at once to the app, the widgets and the reminders.
struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.key, store: AppGroup.defaults) private var language = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("App Language")
                    .font(Theme.display(24))
                    .padding(.top, 24)

                VStack(spacing: 0) {
                    option(code: "", title: String(localized: "Same as iPhone", bundle: .app), subtitle: AppLanguage.nativeName(AppLanguage.system))
                    ForEach(AppLanguage.supported, id: \.self) { code in
                        divider
                        option(code: code, title: AppLanguage.nativeName(code), subtitle: nameInCurrentLanguage(code))
                    }
                }
                .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {
            CircleIconButton(title: "Close", systemImage: "xmark") { dismiss() }
                .padding(12)
        }
        .background { PosterBackdrop(kind: .holiday) }
        .environment(\.colorScheme, .dark)
        .tint(.white)
    }

    private func option(code: String, title: String, subtitle: String?) -> some View {
        let isSelected = language == code
        return Button {
            choose(code)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: title)
                        .font(.body.weight(.medium))
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// "Almanca" under "Deutsch" when the app is in Turkish; nothing for the language already showing.
    private func nameInCurrentLanguage(_ code: String) -> String? {
        guard code != AppLanguage.current else { return nil }
        return AppLanguage.locale.localizedString(forIdentifier: code)?.capitalized(with: AppLanguage.locale)
    }

    private func choose(_ code: String) {
        guard code != language else {
            dismiss()
            return
        }
        // The app rebuilds in the new language as soon as this changes, closing this sheet.
        language = code
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 16)
    }
}
