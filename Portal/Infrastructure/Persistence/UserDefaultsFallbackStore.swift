import Foundation

@MainActor
public final class UserDefaultsFallbackStore: FallbackBrowserPreferenceStore, @unchecked Sendable {
    private nonisolated static let key = "routing.unmatchedLinksFallbackBrowserBundleID"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func fallbackBrowserBundleID() async -> String? {
        self.defaults.string(forKey: Self.key)
    }

    public func setFallbackBrowserBundleID(_ bundleID: String?) async {
        guard let bundleID, !bundleID.isEmpty else {
            self.defaults.removeObject(forKey: Self.key)
            return
        }
        self.defaults.set(bundleID, forKey: Self.key)
    }
}
