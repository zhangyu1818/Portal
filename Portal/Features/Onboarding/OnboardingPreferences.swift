import Foundation

enum OnboardingPreferences {
    private static let key = "OnboardingDismissed_v1"

    static var isDismissed: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markDismissed() {
        UserDefaults.standard.set(true, forKey: self.key)
    }
}
