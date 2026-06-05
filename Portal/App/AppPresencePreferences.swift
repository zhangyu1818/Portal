import Foundation

enum AppPresencePreferences {
    static let showsMenuBarIconKey = "ShowsMenuBarIcon_v1"
    static let defaultShowsMenuBarIcon = true

    static func showsMenuBarIcon(in defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: self.showsMenuBarIconKey) != nil else {
            return self.defaultShowsMenuBarIcon
        }
        return defaults.bool(forKey: self.showsMenuBarIconKey)
    }
}
