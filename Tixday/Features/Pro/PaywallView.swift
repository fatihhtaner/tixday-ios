import SwiftUI

/// Tixday Pro: a fan of tickets, what Pro adds, the two plans, and the fine print;
/// after a purchase or restore it turns into the welcome celebration.
struct PaywallView: View {
    /// Why the paywall opened, so the matching benefit is highlighted.
    var reason: ProFeature?

    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selectedID: String?
    @State private var showsWelcome = false

    private var selected: ProPackage? {
        pro.packages.first { $0.id == selectedID } ?? pro.packages.first { $0.kind == .yearly } ?? pro.packages.first
    }

    var body: some View {
        ZStack {
            if showsWelcome {
                ProWelcomeView { dismiss() }
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                offer
                    .transition(.opacity)
            }
        }
        .background { PosterBackdrop(kind: .concert) }
        .environment(\.colorScheme, .dark)
        .tint(.white)
        .alert("Purchase failed", isPresented: Binding(get: { pro.errorMessage != nil }, set: { if !$0 { pro.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pro.errorMessage ?? "")
        }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro { withAnimation(.easeInOut(duration: 0.35)) { showsWelcome = true } }
        }
    }

    private var offer: some View {
        ScrollView {
            VStack(spacing: 26) {
                ticketFan
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    Text("Tixday Pro")
                        .font(Theme.display(32))
                    Text("Every date you're waiting for, made yours.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                benefits

                plans

                purchaseButton

                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {
            CircleIconButton(title: "Close", systemImage: "xmark") { dismiss() }
                .padding(12)
        }
    }

    // MARK: - Pieces

    private var ticketFan: some View {
        let samples = TicketSnapshot.samples()
        return ZStack {
            ForEach(Array([(1, -12.0, -78.0), (3, 12.0, 78.0), (0, 0.0, 0.0)].enumerated()), id: \.offset) { _, item in
                TicketView(ticket: samples[item.0], size: .small, notchColor: nil)
                    .frame(width: 138, height: 138)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .ticketShadow()
                    .rotationEffect(.degrees(item.1))
                    .offset(x: item.2, y: item.0 == 0 ? -6 : 10)
            }
        }
        .frame(height: 170)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefit("infinity", "Unlimited tickets", "Free includes \(ProStore.freeTicketLimit).", highlighted: reason == .unlimitedTickets)
            benefit("photo.on.rectangle.angled", "Your own photos", "Put any photo on a ticket and its widget.", highlighted: reason == .photos)
            benefit("lock.rectangle.on.rectangle", "Lock Screen widgets", "See the countdown without unlocking.", highlighted: reason == .lockScreen)
            benefit("sparkles", "New poster packs", "Fresh ticket designs as they arrive.", highlighted: false)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func benefit(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey, highlighted: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.white.opacity(highlighted ? 0.28 : 0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var plans: some View {
        VStack(spacing: 10) {
            if pro.packages.isEmpty {
                ProgressView().frame(height: 120)
            }
            ForEach(pro.packages) { package in
                planRow(package)
            }
        }
    }

    private func planRow(_ package: ProPackage) -> some View {
        let isSelected = package.id == selected?.id
        return Button {
            withAnimation(.snappy) { selectedID = package.id }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(package.kind == .lifetime ? "Lifetime" : "Yearly")
                            .font(.body.weight(.semibold))
                        if let trial = package.trial {
                            Text(trial)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.2), in: Capsule())
                        }
                    }
                    Text(package.kind == .lifetime ? String(localized: "Pay once, keep it forever") : package.pricePerMonth.map { String(localized: "Just \($0) a month") } ?? "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(package.price)
                    .font(.headline)
            }
            .padding(16)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous), tint: isSelected ? .white.opacity(0.12) : nil)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(isSelected ? 0.9 : 0), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var purchaseButton: some View {
        Button {
            guard let selected else { return }
            Task { _ = await pro.purchase(selected) }
        } label: {
            Group {
                if pro.isPurchasing {
                    ProgressView().tint(.black)
                } else {
                    Text(selected?.trial != nil ? "Start free trial" : "Continue")
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white, in: Capsule())
        }
        .buttonStyle(PressableStyle())
        .disabled(selected == nil || pro.isPurchasing)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let selected, selected.kind == .yearly {
                Text(selected.trial != nil
                     ? "Free for the trial, then \(selected.price) a year. Cancel anytime in Settings."
                     : "\(selected.price) a year. Cancel anytime in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 18) {
                Button("Restore") { Task { _ = await pro.restore() } }
                Button("Terms") { openURL(AppConfig.termsOfUseURL) }
                Button("Privacy") { openURL(AppConfig.privacyPolicyURL) }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            #if DEBUG
            if pro.usesDebugProducts {
                Text("Debug products: purchases unlock Pro locally.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            #endif
        }
    }
}
