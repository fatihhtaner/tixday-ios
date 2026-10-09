import Foundation
import UserNotifications

/// The user's reminder choices from Settings, kept in the app's own defaults.
enum ReminderSettings {
    static let enabledKey = "remindersEnabled"
    /// Minutes after midnight; 9:00 by default.
    static let timeKey = "reminderMinutes"
    static let defaultMinutes = 9 * 60

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static var minutes: Int {
        UserDefaults.standard.object(forKey: timeKey) as? Int ?? defaultMinutes
    }
}

/// Local reminders before each ticket: a month, a week and a day before, and on the day, at the time
/// chosen in Settings (9:00 by default).
enum TicketNotifications {
    /// iOS keeps at most 64 pending requests per app; stay below it and keep the soonest.
    private static let maxPending = 60

    private enum Milestone: Int, CaseIterable {
        case month = 30, week = 7, day = 1, today = 0

        var body: String {
            switch self {
            case .month: String(localized: "One month to go.")
            case .week: String(localized: "One week to go!")
            case .day: String(localized: "Tomorrow's the day!")
            case .today: String(localized: "Today's the day. Enjoy it!")
            }
        }
    }

    /// The reminders still ahead for a date: days before the event, and when each fires.
    static func reminderDates(
        for date: Date,
        minutes: Int = ReminderSettings.defaultMinutes,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [(daysBefore: Int, fireDate: Date)] {
        let eventDay = calendar.startOfDay(for: date)
        return Milestone.allCases.compactMap { milestone in
            guard
                let day = calendar.date(byAdding: .day, value: -milestone.rawValue, to: eventDay),
                let fireDate = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                fireDate > now
            else { return nil }
            return (milestone.rawValue, fireDate)
        }
    }

    /// Asks once, the first time the user saves a ticket.
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Replaces every pending reminder with a fresh plan for these tickets.
    static func reschedule(_ tickets: [TicketSnapshot], now: Date = .now, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard ReminderSettings.isEnabled else { return }
        let minutes = ReminderSettings.minutes

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        var plan: [(fireDate: Date, request: UNNotificationRequest)] = []
        for ticket in tickets {
            for (daysBefore, fireDate) in reminderDates(for: ticket.date, minutes: minutes, now: now, calendar: calendar) {
                guard let milestone = Milestone(rawValue: daysBefore) else { continue }

                let content = UNMutableNotificationContent()
                content.title = ticket.title
                content.body = milestone.body
                content.sound = .default
                content.userInfo = ["ticketID": ticket.id.uuidString]

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "\(ticket.id.uuidString)-\(milestone.rawValue)", content: content, trigger: trigger)
                plan.append((fireDate, request))
            }
        }

        for item in plan.sorted(by: { $0.fireDate < $1.fireDate }).prefix(maxPending) {
            try? await center.add(item.request)
        }
        #if DEBUG
        print("TicketNotifications: \(await center.pendingNotificationRequests().count) reminders pending")
        #endif
    }
}
