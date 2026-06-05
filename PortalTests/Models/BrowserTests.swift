import Foundation
@testable import Portal
import Testing

@Suite("Browser")
struct BrowserTests {
    @Test("id matches bundleIdentifier")
    func idMatchesBundleIdentifier() {
        let browser = Browser(
            bundleIdentifier: "com.apple.safari",
            displayName: "Safari",
            bundleURL: URL(filePath: "/Applications/Safari.app")
        )
        #expect(browser.id == browser.bundleIdentifier)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = Browser(
            bundleIdentifier: "com.google.Chrome",
            displayName: "Google Chrome",
            bundleURL: URL(filePath: "/Applications/Google Chrome.app")
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Browser.self, from: data)
        #expect(decoded == original)
        #expect(decoded.bundleIdentifier == original.bundleIdentifier)
        #expect(decoded.displayName == original.displayName)
        #expect(decoded.bundleURL == original.bundleURL)
    }

    @Test("Hashable equality based on all fields")
    func hashableEquality() {
        let url = URL(filePath: "/Applications/Safari.app")
        let safari = Browser(bundleIdentifier: "com.apple.safari", displayName: "Safari", bundleURL: url)
        let safariCopy = Browser(bundleIdentifier: "com.apple.safari", displayName: "Safari", bundleURL: url)
        let firefox = Browser(bundleIdentifier: "com.mozilla.firefox", displayName: "Firefox", bundleURL: url)
        #expect(safari == safariCopy)
        #expect(safari != firefox)
        #expect(Set([safari, safariCopy]).count == 1)
        #expect(Set([safari, firefox]).count == 2)
    }
}
