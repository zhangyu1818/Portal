import Foundation
@testable import Portal
import Testing

@Suite("URLRouter edge cases")
@MainActor
struct URLRouterEdgeCaseTests {
    private let safariBundle = "com.apple.safari"

    private func makeSafari() -> Browser {
        Browser(
            bundleIdentifier: self.safariBundle,
            displayName: "Safari",
            bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
        )
    }

    @Test("launchFailureIsSwallowed — launcher throws, route does not propagate")
    func launchFailureIsSwallowed() async throws {
        struct LaunchBoom: Error {}
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))
        let rule = Rule.domain(DomainRule(pattern: "example.com", browserBundleID: self.safariBundle))

        let components = makeRouter(
            ruleMatch: .rule(rule),
            browsers: [safari],
            loopGuardAllow: true,
            launchError: LaunchBoom()
        )

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        #expect(calls.isEmpty)
    }

    @Test("multipleURLsWithMixedMatches — first URL launches via rule, second presents picker")
    func multipleURLsWithMixedMatches() async throws {
        let safari = self.makeSafari()
        let urlA = try #require(URL(string: "https://example.com"))
        let urlB = try #require(URL(string: "https://unmatched.com"))
        let rule = Rule.domain(DomainRule(pattern: "example.com", browserBundleID: self.safariBundle))

        let components = makeRouter(
            perURLMatches: [urlA: .rule(rule), urlB: .noMatch],
            browsers: [safari],
            loopGuardAllow: true,
            pickerChoice: nil
        )

        await components.router.route([urlA, urlB])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(calls.count == 1)
        #expect(calls[0].url == urlA)
        #expect(presentations == [urlB])
    }

    @Test("concurrentRouteCallsBothPersistRules — two route() calls each appending preserve both rules")
    func concurrentRouteCallsBothPersistRules() async throws {
        let safari = self.makeSafari()
        let urlA = try #require(URL(string: "https://alpha.test"))
        let urlB = try #require(URL(string: "https://beta.test"))
        let choice = PickerChoice(browser: safari, remember: true)

        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = JSONFileRuleStore(directory: dir)
        defer { try? FileManager.default.removeItem(at: dir) }

        let router = URLRouter(
            ruleStore: store,
            ruleEngine: MockRuleEngine(match: .noMatch),
            sourceAppDetector: MockSourceAppDetector(source: nil),
            browserLauncher: MockBrowserLauncher(),
            browserRegistry: MockBrowserRegistry(browsers: [safari]),
            loopGuard: MockLoopGuard(allow: true),
            pickerCoordinator: MockPickerCoordinator(choice: choice)
        )

        async let first: Void = router.route([urlA])
        async let second: Void = router.route([urlB])
        _ = await (first, second)

        let persisted = try await store.load()
        let hosts = persisted.compactMap { rule -> String? in
            if case let .domain(domain) = rule { return domain.pattern }
            return nil
        }
        #expect(hosts.contains("alpha.test"))
        #expect(hosts.contains("beta.test"))
        #expect(persisted.count == 2)
    }

    @Test("loadFailureDoesNotClobberRules — load throws, picker still shown, no save occurs")
    func loadFailureDoesNotClobberRules() async throws {
        struct LoadBoom: Error {}
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))
        let choice = PickerChoice(browser: safari, remember: true)

        let components = makeRouter(
            ruleMatch: .noMatch,
            loopGuardAllow: true,
            pickerChoice: choice,
            loadError: LoadBoom()
        )

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let saves = await components.ruleStore.savedRuleSets
        let calls = await components.launcher.recordedCalls
        #expect(presentations == [url])
        #expect(saves.isEmpty)
        #expect(calls.count == 1)
    }

    @Test("fallbackBrowserMissingFallsBackToPicker")
    func fallbackBrowserMissingFallsBackToPicker() async throws {
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(
            ruleMatch: .noMatch,
            browsers: [],
            pickerChoice: nil,
            fallbackBrowserBundleID: self.safariBundle
        )

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let calls = await components.launcher.recordedCalls
        #expect(presentations == [url])
        #expect(calls.isEmpty)
    }

    @Test("loadFailureDoesNotUseFallbackBrowser")
    func loadFailureDoesNotUseFallbackBrowser() async throws {
        struct LoadBoom: Error {}
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(
            ruleMatch: .noMatch,
            browsers: [safari],
            pickerChoice: nil,
            loadError: LoadBoom(),
            fallbackBrowserBundleID: safari.bundleIdentifier
        )

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let calls = await components.launcher.recordedCalls
        #expect(presentations == [url])
        #expect(calls.isEmpty)
    }
}
