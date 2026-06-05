import AppKit
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

    @Test("workspace launcher resolves stale browser urls by bundle identifier")
    func workspaceLauncherResolvesStaleBrowserURLsByBundleIdentifier() async throws {
        let staleURL = URL(fileURLWithPath: "/Applications/Missing Browser.app")
        let resolvedURL = URL(fileURLWithPath: "/Applications/Resolved Browser.app")
        let bundleIdentifier = "com.example.resolved-browser"
        let browser = Browser(
            bundleIdentifier: bundleIdentifier,
            displayName: "Resolved Browser",
            bundleURL: staleURL
        )
        let recorder = WorkspaceOpenRecorder()
        let launcher = WorkspaceBrowserLauncher(
            applicationURLForBundleIdentifier: { bundleID in
                bundleID == bundleIdentifier ? resolvedURL : nil
            },
            fileExists: { path in
                path == resolvedURL.path(percentEncoded: false)
            },
            openURLs: { urls, appURL, _ in
                await recorder.record(urls: urls, appURL: appURL)
            }
        )

        try await launcher.launch(self.testURL, in: browser)

        let calls = await recorder.calls
        #expect(calls == [
            WorkspaceOpenRecorder.Call(urls: [self.testURL], appURL: resolvedURL),
        ])
    }

    @Test("workspace launcher prefers the current bundle identifier location")
    func workspaceLauncherPrefersCurrentBundleIdentifierLocation() async throws {
        let cachedURL = URL(fileURLWithPath: "/Applications/Cached Browser.app")
        let resolvedURL = URL(fileURLWithPath: "/Applications/Resolved Browser.app")
        let bundleIdentifier = "com.example.resolved-browser"
        let browser = Browser(
            bundleIdentifier: bundleIdentifier,
            displayName: "Resolved Browser",
            bundleURL: cachedURL
        )
        let recorder = WorkspaceOpenRecorder()
        let launcher = WorkspaceBrowserLauncher(
            applicationURLForBundleIdentifier: { bundleID in
                bundleID == bundleIdentifier ? resolvedURL : nil
            },
            fileExists: { path in
                path == cachedURL.path(percentEncoded: false)
                    || path == resolvedURL.path(percentEncoded: false)
            },
            openURLs: { urls, appURL, _ in
                await recorder.record(urls: urls, appURL: appURL)
            }
        )

        try await launcher.launch(self.testURL, in: browser)

        let calls = await recorder.calls
        #expect(calls == [
            WorkspaceOpenRecorder.Call(urls: [self.testURL], appURL: resolvedURL),
        ])
    }

    @Test("workspace launcher throws browserNotFound when cached and resolved urls are unavailable")
    func workspaceLauncherThrowsWhenCachedAndResolvedURLsAreUnavailable() async {
        let bundleIdentifier = "com.example.missing-browser"
        let browser = Browser(
            bundleIdentifier: bundleIdentifier,
            displayName: "Missing Browser",
            bundleURL: URL(fileURLWithPath: "/Applications/Missing Browser.app")
        )
        let recorder = WorkspaceOpenRecorder()
        let launcher = WorkspaceBrowserLauncher(
            applicationURLForBundleIdentifier: { _ in
                URL(fileURLWithPath: "/Applications/Also Missing Browser.app")
            },
            fileExists: { _ in false },
            openURLs: { urls, appURL, _ in
                await recorder.record(urls: urls, appURL: appURL)
            }
        )

        await #expect(throws: BrowserLauncherError.browserNotFound(bundleIdentifier: bundleIdentifier)) {
            try await launcher.launch(self.testURL, in: browser)
        }

        let calls = await recorder.calls
        #expect(calls.isEmpty)
    }
}

private actor WorkspaceOpenRecorder {
    struct Call: Equatable {
        let urls: [URL]
        let appURL: URL
    }

    private(set) var calls: [Call] = []

    func record(urls: [URL], appURL: URL) {
        self.calls.append(Call(urls: urls, appURL: appURL))
    }
}
