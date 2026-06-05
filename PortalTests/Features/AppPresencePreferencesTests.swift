import Foundation
@testable import Portal
import Testing

@Suite("AppPresencePreferences")
struct AppPresencePreferencesTests {
    @Test("menu bar icon is shown by default")
    func menuBarIconIsShownByDefault() throws {
        let defaults = try Self.makeDefaults()

        #expect(AppPresencePreferences.showsMenuBarIcon(in: defaults) == true)
    }

    @Test("stored menu bar icon preference is respected")
    func storedMenuBarIconPreferenceIsRespected() throws {
        let defaults = try Self.makeDefaults()

        defaults.set(false, forKey: AppPresencePreferences.showsMenuBarIconKey)

        #expect(AppPresencePreferences.showsMenuBarIcon(in: defaults) == false)
    }

    private static func makeDefaults() throws -> UserDefaults {
        let suiteName = "dev.zhangyu.portal.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
