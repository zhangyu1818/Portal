import Foundation

public protocol FallbackBrowserPreferenceStore: Sendable {
    func fallbackBrowserBundleID() async -> String?
    func setFallbackBrowserBundleID(_ bundleID: String?) async
}
