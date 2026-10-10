import SwiftUI

/// First launch: what Tixday is, where the countdown shows up, and the reminders, then straight
/// into creating the first ticket.
struct OnboardingView: View {
    /// Called when onboarding ends; true when the user wants to create a ticket right away.
    var onFinish: (_ createTicket: Bool) -> Void

    @State private var page = 0
    /// Pages already shown; each illustration plays its entrance the first time.
    @State private var seen: Set<Int> = []
    private let pageCount = 3
    private let samples = TicketSnapshot.samples()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < pageCount - 1 {
                    Button("Skip") { onFinish(false) }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
            }
            .frame(height: 44)

            TabView(selection: $page) {
                OnboardingPage(
                    title: "Every date is a ticket",
                    message: "Flights, concerts, exams, birthdays: turn the days you're waiting for into tickets that count down.",
                    isActive: seen.contains(0)
                ) { isActive in TicketFan(samples: samples, isActive: isActive) }
                    .tag(0)
                OnboardingPage(
                    title: "Always in sight",
                    message: "Add a widget to your Home Screen or Lock Screen and see how many days are left at a glance.",
                    isActive: seen.contains(1)
                ) { isActive in WidgetPreview(ticket: samples[0], lockTicket: samples[1], isActive: isActive) }
                    .tag(1)
                OnboardingPage(
                    title: "Never miss the day",
                    message: "Tixday reminds you a month, a week and a day before, and on the day itself.",
                    isActive: seen.contains(2)
                ) { isActive in ReminderPreview(isActive: isActive) }
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: page) { _, newPage in seen.insert(newPage) }

            VStack(spacing: 18) {
                dots
                Button {
                    if page < pageCount - 1 {
                        withAnimation(.snappy) { page += 1 }
                    } else {
                        onFinish(true)
                    }
                } label: {
                    Text(page < pageCount - 1 ? "Continue" : "Create my first ticket")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white, in: Capsule())
                        .contentShape(Capsule())
                        .contentTransition(.opacity)
                }
                .buttonStyle(PressableStyle())

                Button("Maybe later") { onFinish(false) }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(height: 22)
                    .opacity(page == pageCount - 1 ? 1 : 0)
                    .disabled(page < pageCount - 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background {
            PosterBackdrop(kind: [TicketKind.concert, .flight, .wedding][page])
                .animation(.easeInOut(duration: 0.5), value: page)
        }
        .environment(\.colorScheme, .dark)
        .tint(.white)
        .sensoryFeedback(.selection, trigger: page)
        .task {
            // Let the screen settle before the first illustration deals its tickets.
            try? await Task.sleep(for: .milliseconds(250))
            seen.insert(0)
        }
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index == page ? 1 : 0.3))
                    .frame(width: index == page ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy, value: page)
        .accessibilityHidden(true)
    }
}

/// An illustration with a title and a sentence.
private struct OnboardingPage<Art: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    /// False until the page is first shown, so the illustration's entrance plays in view.
    let isActive: Bool
    @ViewBuilder var art: (_ isActive: Bool) -> Art

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            art(isActive || reduceMotion)
                .frame(height: 300)
                .animation(.spring(response: 0.7, dampingFraction: 0.75), value: isActive)
            VStack(spacing: 10) {
                Text(title)
                    .font(Theme.display(26))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
        }
    }
}

/// Three tickets dealt into a fan.
private struct TicketFan: View {
    let samples: [TicketSnapshot]
    let isActive: Bool

    var body: some View {
        ZStack {
            ForEach(Array([(4, -12.0, -74.0, 18.0), (5, 11.0, 74.0, 22.0), (1, 0.0, 0.0, 0.0)].enumerated()), id: \.offset) { _, item in
                TicketView(ticket: samples[item.0], size: .small, notchColor: nil)
                    .frame(width: 158, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .ticketShadow()
                    .rotationEffect(.degrees(isActive ? item.1 : 0))
                    .offset(x: isActive ? item.2 : 0, y: isActive ? item.3 : 40)
                    .opacity(isActive ? 1 : 0)
            }
        }
    }
}

/// A Home Screen widget and a Lock Screen countdown, as the user will see them.
private struct WidgetPreview: View {
    let ticket: TicketSnapshot
    let lockTicket: TicketSnapshot
    let isActive: Bool

    var body: some View {
        VStack(spacing: 16) {
            TicketView(ticket: ticket, size: .medium, notchColor: nil)
                .frame(width: 330, height: 155)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .ticketShadow()
                .offset(y: isActive ? 0 : 30)
                .opacity(isActive ? 1 : 0)

            HStack(spacing: 12) {
                Image(systemName: lockTicket.kind.symbol)
                    .font(.system(size: 18, weight: .semibold))
                VStack(alignment: .leading, spacing: 0) {
                    let days = DayCount.days(until: lockTicket.date)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(verbatim: CountLabel.number(for: days))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text(verbatim: CountLabel.text(for: days))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(verbatim: lockTicket.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 330)
            .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .offset(y: isActive ? 0 : 40)
            .opacity(isActive ? 1 : 0)
            .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.12), value: isActive)
        }
    }
}

/// The four reminders, landing one after another under a ringing bell.
private struct ReminderPreview: View {
    let isActive: Bool

    private var milestones: [LocalizedStringKey] {
        ["A month before", "A week before", "The day before", "On the day"]
    }

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 40, weight: .semibold))
                .symbolEffect(.bounce, value: isActive)
                .frame(width: 92, height: 92)
                .glassBackground(in: Circle())
                .scaleEffect(isActive ? 1 : 0.6)
                .opacity(isActive ? 1 : 0)

            VStack(spacing: 10) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                    HStack(spacing: 10) {
                        Image(systemName: index == milestones.count - 1 ? "star.fill" : "clock")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(index == milestones.count - 1 ? Color(hex: "#F2C14E") : .secondary)
                        Text(milestone)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .frame(width: 260)
                    .glassBackground(in: Capsule())
                    .offset(x: isActive ? 0 : 40)
                    .opacity(isActive ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.09), value: isActive)
                }
            }
        }
    }
}
