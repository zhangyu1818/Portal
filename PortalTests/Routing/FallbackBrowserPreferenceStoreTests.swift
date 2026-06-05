import Foundation
@testable import Portal
import Testing

@Suite("UserDefaultsFallbackStore")
@MainActor
struct FallbackBrowserPreferenceStoreTests {
    @Test("default selection asks every time")
    func defaultSelectionAsksEveryTime() async throws {
        let defaults = try Self.makeDefaults()
        let store = UserDefaultsFallbackStore(defaults: defaults)

        let selection = await store.fallbackBrowserBundleID()

        #expect(selection == nil)
    }

    @Test("set and clear fallback browser bundle identifier")
    func setAndClearFallbackBrowserBundleIdentifier() async throws {
        let defaults = try Self.makeDefaults()
        let store = UserDefaultsFallbackStore(defaults: defaults)

        await store.setFallbackBrowserBundleID("com.apple.Safari")
        #expect(await store.fallbackBrowserBundleID() == "com.apple.Safari")

        await store.setFallbackBrowserBundleID(nil)
        #expect(await store.fallbackBrowserBundleID() == nil)
    }

    private static func makeDefaults() throws -> UserDefaults {
        let suiteName = "Portal.FallbackBrowserPreferenceStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
