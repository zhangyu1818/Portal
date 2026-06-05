import Foundation
@testable import Portal
import Testing

@Suite("URLRouter")
@MainActor
struct URLRouterTests {
    private let safariBundle = "com.apple.safari"

    private func makeSafari() -> Browser {
        Browser(
            bundleIdentifier: self.safariBundle,
            displayName: "Safari",
            bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
        )
    }

    @Test("ruleHitDispatchesToBrowser — engine returns matching rule, launches that browser")
    func ruleHitDispatchesToBrowser() async throws {
        let safari = self.makeSafari()
        let domainRule = DomainRule(pattern: "example.com", browserBundleID: self.safariBundle)
        let rule = Rule.domain(domainRule)
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(ruleMatch: .rule(rule), browsers: [safari], loopGuardAllow: true)

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(calls.count == 1)
        #expect(calls[0].url == url)
        #expect(calls[0].browser == safari)
        #expect(presentations.isEmpty)
    }

    @Test("noMatchShowsPicker — engine returns noMatch, picker presented; nil choice means no launch")
    func noMatchShowsPicker() async throws {
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(ruleMatch: .noMatch, pickerChoice: nil)

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(presentations.count == 1)
        #expect(presentations[0] == url)
        #expect(calls.isEmpty)
    }

    @Test("pickerChoiceWithoutRememberLaunches — no rule saved, browser launched")
    func pickerChoiceWithoutRememberLaunches() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))
        let choice = PickerChoice(browser: safari, remember: false)

        let components = makeRouter(ruleMatch: .noMatch, loopGuardAllow: true, pickerChoice: choice)

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let saves = await components.ruleStore.savedRuleSets
        #expect(calls.count == 1)
        #expect(calls[0].browser == safari)
        #expect(saves.isEmpty)
    }

    @Test("pickerChoiceWithRememberSavesDomainRule — rule saved with url host, browser launched")
    func pickerChoiceWithRememberSavesDomainRule() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com/some/path"))
        let choice = PickerChoice(browser: safari, remember: true)

        let components = makeRouter(ruleMatch: .noMatch, loopGuardAllow: true, pickerChoice: choice)

        await components.router.route([url])

        let saves = await components.ruleStore.savedRuleSets
        let calls = await components.launcher.recordedCalls
        try #require(saves.count == 1)
        let domainRules = saves[0].compactMap { rule -> DomainRule? in
            if case let .domain(inner) = rule { return inner }
            return nil
        }
        try #require(domainRules.count == 1)
        #expect(domainRules[0].pattern == "example.com")
        #expect(domainRules[0].browserBundleID == self.safariBundle)
        #expect(calls.count == 1)
    }

    @Test("loopGuardBlocksLaunch — loop guard returns false, no launch")
    func loopGuardBlocksLaunch() async throws {
        let safari = self.makeSafari()
        let domainRule = DomainRule(pattern: "example.com", browserBundleID: self.safariBundle)
        let rule = Rule.domain(domainRule)
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(ruleMatch: .rule(rule), browsers: [safari], loopGuardAllow: false)

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        #expect(calls.isEmpty)
    }

    @Test("unknownBrowserBundleFallsBackToPicker — rule browser not in registry, picker shown")
    func unknownBrowserBundleFallsBackToPicker() async throws {
        let domainRule = DomainRule(pattern: "example.com", browserBundleID: "com.unknown.browser")
        let rule = Rule.domain(domainRule)
        let url = try #require(URL(string: "https://example.com"))

        let components = makeRouter(ruleMatch: .rule(rule), browsers: [], pickerChoice: nil)

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        let calls = await components.launcher.recordedCalls
        #expect(presentations.count == 1)
        #expect(calls.isEmpty)
    }

    @Test("urlWithNoHostRememberDoesNotSaveRule — no host means no domain rule saved")
    func urlWithNoHostRememberDoesNotSaveRule() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "mailto:test@example.com"))
        let choice = PickerChoice(browser: safari, remember: true)

        let components = makeRouter(ruleMatch: .noMatch, loopGuardAllow: true, pickerChoice: choice)

        await components.router.route([url])

        let saves = await components.ruleStore.savedRuleSets
        let calls = await components.launcher.recordedCalls
        #expect(saves.isEmpty)
        #expect(calls.count == 1)
    }

    @Test("disabledRuleSkippedHandsOffToPicker — engine returns noMatch for disabled rule")
    func disabledRuleSkippedHandsOffToPicker() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let disabledRule = Rule.domain(DomainRule(
            pattern: "example.com",
            browserBundleID: self.safariBundle,
            enabled: false
        ))

        let components = makeRouter(rules: [disabledRule], ruleMatch: .noMatch, pickerChoice: nil)

        await components.router.route([url])

        let presentations = await components.picker.presentedURLs
        #expect(presentations.count == 1)
    }

    @Test("source is Portal self skips all URLs (self-loop guard)")
    @MainActor
    func sourceIsPortalSelfSkipsAllURLs() async throws {
        let safari = self.makeSafari()
        let url = try #require(URL(string: "https://example.com"))
        let selfBundleID = Bundle.main.bundleIdentifier ?? "dev.zhangyu.portal"
        let selfApp = SourceApp(bundleIdentifier: selfBundleID, displayName: "Portal")
        let domainRule = DomainRule(pattern: "example.com", browserBundleID: self.safariBundle)
        let components = makeRouter(
            ruleMatch: .rule(.domain(domainRule)),
            sourceApp: selfApp,
            browsers: [safari],
            loopGuardAllow: true
        )

        await components.router.route([url])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(calls.isEmpty)
        #expect(presentations.isEmpty)
    }

    @Test("emptyURLArrayDoesNothing — no calls to any dependency")
    func emptyURLArrayDoesNothing() async {
        let components = makeRouter()

        await components.router.route([])

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        let saves = await components.ruleStore.savedRuleSets
        #expect(calls.isEmpty)
        #expect(presentations.isEmpty)
        #expect(saves.isEmpty)
    }

    @Test("multipleURLsRoutedSequentially — both URLs launched")
    func multipleURLsRoutedSequentially() async throws {
        let safari = self.makeSafari()
        let urlA = try #require(URL(string: "https://example.com"))
        let urlB = try #require(URL(string: "https://other.com"))
        let domainRule = DomainRule(pattern: "example.com", browserBundleID: self.safariBundle)
        let rule = Rule.domain(domainRule)

        let components = makeRouter(ruleMatch: .rule(rule), browsers: [safari], loopGuardAllow: true)

        await components.router.route([urlA, urlB])

        let calls = await components.launcher.recordedCalls
        #expect(calls.count == 2)
        #expect(calls[0].url == urlA)
        #expect(calls[1].url == urlB)
    }
}
