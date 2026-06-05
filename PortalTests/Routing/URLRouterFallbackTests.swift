import Foundation
@testable import Portal
import Testing

@Suite("URLRouter fallback browser")
@MainActor
struct URLRouterFallbackTests {
    private let safariBundle = "com.apple.safari"

    private func makeSafari() -> Browser {
        Browser(
            bundleIdentifier: self.safariBundle,
            displayName: "Safari",
            bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
        )
    }

    @Test("no match with fallback browser launches fallback without picker")
    func noMatchWithFallbackBrowserLaunchesFallbackWithoutPicker() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(
            ruleMatch: .noMatch,
            browsers: [safari],
            loopGuardAllow: true,
            fallbackBrowserBundleID: safari.bundleIdentifier
        )

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        let saves = await components.ruleStore.savedRuleSets
        #expect(calls.count == 1)
        #expect(calls[0].url == url)
        #expect(calls[0].browser == safari)
        #expect(presentations.isEmpty)
        #expect(saves.isEmpty)
    }

    @Test("rule hit takes priority over fallback browser")
    func ruleHitTakesPriorityOverFallbackBrowser() async throws {
        let safari = self.makeSafari()
        let chrome = Browser(
            bundleIdentifier: "com.google.Chrome",
            displayName: "Google Chrome",
            bundleURL: URL(fileURLWithPath: "/Applications/Google Chrome.app")
        )
        let url = try #require(URL(string: "https://example.com"))
        let rule = Rule.domain(DomainRule(pattern: "example.com", browserBundleID: chrome.bundleIdentifier))

        let components = makeRouter(
            ruleMatch: .rule(rule),
            browsers: [safari, chrome],
            loopGuardAllow: true,
            fallbackBrowserBundleID: safari.bundleIdentifier
        )

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(calls.count == 1)
        #expect(calls[0].browser == chrome)
        #expect(presentations.isEmpty)
    }

    @Test("rule target missing does not use fallback browser")
    func ruleTargetMissingDoesNotUseFallbackBrowser() async throws {
        let safari = self.makeSafari()
        let rule = Rule.domain(DomainRule(pattern: "example.com", browserBundleID: "com.unknown.browser"))
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(
            ruleMatch: .rule(rule),
            browsers: [safari],
            pickerChoice: nil,
            fallbackBrowserBundleID: safari.bundleIdentifier
        )

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let calls = await components.launcher.recordedCalls
        #expect(presentations == [url])
        #expect(calls.isEmpty)
    }

    @Test("fallback browser not found during launch refreshes registry and presents picker")
    func fallbackBrowserNotFoundDuringLaunchRefreshesRegistryAndPresentsPicker() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(
            ruleMatch: .noMatch,
            browsers: [safari],
            loopGuardAllow: true,
            pickerChoice: nil,
            launchError: BrowserLauncherError.browserNotFound(bundleIdentifier: safari.bundleIdentifier),
            fallbackBrowserBundleID: safari.bundleIdentifier
        )

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let calls = await components.launcher.recordedCalls
        let refreshCallCount = await components.registry.refreshCallCount
        #expect(presentations == [url])
        #expect(calls.isEmpty)
        #expect(refreshCallCount == 1)
    }
}
