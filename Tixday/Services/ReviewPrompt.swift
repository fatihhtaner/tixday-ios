import Foundation

/// When to ask for a rating: only right after a good moment (a second ticket, or a ticket's day
/// arriving), and at most once every four months. iOS itself shows the prompt at most three times a year.
enum ReviewPrompt {
    private static let lastAskedKey = "review.lastAsked"
    private static let minimumGap: TimeInterval = 120 * 86_400

    static func isDue(now: Date = .now) -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastAskedKey) as? Date else { return true }
        return now.timeIntervalSince(last) >= minimumGap
    }

    static func markAsked(now: Date = .now) {
        UserDefaults.standard.set(now, forKey: lastAskedKey)
    }
}
