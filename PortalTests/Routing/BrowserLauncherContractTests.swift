import Foundation
@testable import Portal
import Testing

@Suite("BrowserLauncher")
struct BrowserLauncherContractTests {
    private let testURL: URL
    private let testBrowser: Browser

    init() throws {
        self.testURL = try #require(URL(string: "https://example.com"))
        self.testBrowser = Browser(
            bundleIdentifier: "com.apple.safari",
            displayName: "Safari",
            bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
        )
    }

    @Test("mock records the url and browser from a launch call")
    func mockRecordsCalls() async throws {
        let mock = MockBrowserLauncher()
        try await mock.launch(self.testURL, in: self.testBrowser)
        let calls = await mock.recordedCalls
        try #require(calls.count == 1)
        #expect(calls[0].url == self.testURL)
        #expect(calls[0].browser == self.testBrowser)
    }

    @Test("mock rethrows the configured error")
    func mockThrowsAsConfigured() async {
        let mock = MockBrowserLauncher(throwing: BrowserLauncherError.browserNotFound(bundleIdentifier: "x"))
        await #expect(throws: BrowserLauncherError.browserNotFound(bundleIdentifier: "x")) {
            try await mock.launch(self.testURL, in: self.testBrowser)
        }
    }

    @Test("browserNotFound errors are equal when bundle IDs match")
    func errorEqualityBrowserNotFound() {
        let lhs = BrowserLauncherError.browserNotFound(bundleIdentifier: "x")
        let rhs = BrowserLauncherError.browserNotFound(bundleIdentifier: "x")
        #expect(lhs == rhs)
    }

    @Test("browserNotFound differs from launchFailed")
    func errorInequalityAcrossVariants() {
        let notFound = BrowserLauncherError.browserNotFound(bundleIdentifier: "x")
        let failed = BrowserLauncherError.launchFailed(underlying: URLError(.badURL))
        #expect(notFound != failed)
    }

    @Test("browserNotFound errors differ when bundle IDs differ")
    func errorInequalityDifferentBundleIDs() {
        let lhs = BrowserLauncherError.browserNotFound(bundleIdentifier: "x")
        let rhs = BrowserLauncherError.browserNotFound(bundleIdentifier: "y")
        #expect(lhs != rhs)
    }

    @Test("launchFailed instances are always equal regardless of underlying error")
    func launchFailedEqualityIsType() {
        let lhs = BrowserLauncherError.launchFailed(underlying: URLError(.badURL))
        let rhs = BrowserLauncherError.launchFailed(underlying: URLError(.timedOut))
        #expect(lhs == rhs)
    }
}
