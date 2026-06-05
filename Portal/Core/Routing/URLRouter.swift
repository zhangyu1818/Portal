import Foundation

@MainActor
public final class URLRouter {
    private let ruleStore: any RuleStore
    private let ruleEngine: any RuleEngine
    private let sourceAppDetector: any SourceAppDetector
    private let browserLauncher: any BrowserLauncher
    private let browserRegistry: any BrowserRegistry
    private let loopGuard: any LoopGuardProtocol
    private let pickerCoordinator: any PickerCoordinator
    private let fallbackHandler: FallbackBrowserHandler

    public init(
        ruleStore: some RuleStore,
        ruleEngine: some RuleEngine,
        sourceAppDetector: some SourceAppDetector,
        browserLauncher: some BrowserLauncher,
        browserRegistry: some BrowserRegistry,
        loopGuard: some LoopGuardProtocol,
        pickerCoordinator: some PickerCoordinator,
        fallbackPreferenceStore: some FallbackBrowserPreferenceStore = UserDefaultsFallbackStore()
    ) {
        self.ruleStore = ruleStore
        self.ruleEngine = ruleEngine
        self.sourceAppDetector = sourceAppDetector
        self.browserLauncher = browserLauncher
        self.browserRegistry = browserRegistry
        self.loopGuard = loopGuard
        self.pickerCoordinator = pickerCoordinator
        self.fallbackHandler = FallbackBrowserHandler(
            preferenceStore: fallbackPreferenceStore,
            browserRegistry: browserRegistry,
            loopGuard: loopGuard,
            browserLauncher: browserLauncher
        )
    }

    public func route(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }

        let sourceApp = await sourceAppDetector.currentSource()
        await self.route(urls, sourceApp: sourceApp, sourceMode: "detector")
    }

    public func route(_ urls: [URL], sourceApp: SourceApp?) async {
        await self.route(urls, sourceApp: sourceApp, sourceMode: "appleEvent")
    }

    private func route(_ urls: [URL], sourceApp: SourceApp?, sourceMode: String) async {
        guard !urls.isEmpty else { return }

        PortalDebugLog.route("router.route.start", [("urls", self.describe(urls))])
        PortalDebugLog.route("router.route.source", [
            ("source", self.describe(sourceApp)),
            ("mode", sourceMode),
        ])

        // All URLs in one route(_:) call share a single Apple Event sender.
        // If Portal opened these URLs itself, routing them again would cause an infinite loop.
        if let sourceBundle = sourceApp?.bundleIdentifier, sourceBundle == Bundle.main.bundleIdentifier {
            PortalDebugLog.route("router.route.skip", [
                ("reason", "selfSource"),
                ("source", sourceBundle),
            ])
            return
        }

        // Distinguish "loaded but empty" from "load failed" so we never
        // overwrite rules.json with [] based on a known-stale snapshot.
        let initial: [Rule]?
        do {
            initial = try await self.ruleStore.load()
            PortalDebugLog.route("router.rules.load", [
                ("status", "success"),
                ("count", "\(initial?.count ?? 0)"),
                ("rules", self.describe(initial ?? [])),
            ])
        } catch {
            initial = nil
            PortalDebugLog.route("router.rules.load", [
                ("status", "failed"),
                ("error", String(describing: error)),
            ])
        }

        for url in urls {
            await self.routeSingle(url, sourceApp: sourceApp, rules: initial)
        }
    }

    private func routeSingle(_ url: URL, sourceApp: SourceApp?, rules: [Rule]?) async {
        let input = RoutingInput(url: url, sourceApp: sourceApp)
        let match = self.ruleEngine.evaluate(input, against: rules ?? [])
        PortalDebugLog.route("router.evaluate", [
            ("url", url.absoluteString),
            ("source", self.describe(sourceApp)),
            ("match", self.describe(match)),
        ])

        switch match {
        case let .rule(rule):
            await self.handleRuleMatch(rule, url: url, sourceApp: sourceApp, rules: rules)
        case .noMatch:
            await self.handleNoRuleMatch(url: url, sourceApp: sourceApp, loadedRules: rules)
        }
    }

    private func handleRuleMatch(_ rule: Rule, url: URL, sourceApp: SourceApp?, rules: [Rule]?) async {
        let bundleID = rule.browserBundleID
        let browsers = await browserRegistry.current()
        PortalDebugLog.route("router.ruleMatch", [
            ("url", url.absoluteString),
            ("rule", self.describe(rule)),
            ("availableBrowsers", self.describe(browsers)),
        ])
        guard let browser = browsers.first(where: { $0.bundleIdentifier == bundleID }) else {
            PortalDebugLog.route("router.ruleMatch.fallback", [
                ("target", "picker"),
                ("reason", "browserNotFound"),
                ("bundleID", bundleID),
            ])
            await self.presentPicker(url: url, sourceApp: sourceApp, loadedRules: rules)
            return
        }

        guard await self.loopGuard.recordAndCheck(url: url, browserBundleID: bundleID) else {
            PortalDebugLog.route("router.ruleMatch.blockedByLoopGuard", [
                ("url", url.absoluteString),
                ("browser", bundleID),
            ])
            return
        }

        do {
            try await self.browserLauncher.launch(url, in: browser)
            self.logLaunch(status: "success", url: url, browser: browser.bundleIdentifier)
        } catch {
            self.logLaunch(
                status: "failed",
                url: url,
                browser: browser.bundleIdentifier,
                error: error
            )
            #if DEBUG
                print("[URLRouter] Launch failed for host \(url.host() ?? "<no host>"): \(error)")
            #endif
        }
    }

    private func handleNoRuleMatch(url: URL, sourceApp: SourceApp?, loadedRules: [Rule]?) async {
        if await self.fallbackHandler.openIfAvailable(url: url, loadedRules: loadedRules) {
            return
        }

        await self.presentPicker(url: url, sourceApp: sourceApp, loadedRules: loadedRules)
    }

    private func presentPicker(url: URL, sourceApp: SourceApp?, loadedRules: [Rule]?) async {
        // Defense in depth: gate the picker itself against rapid repeats so a
        // misbehaving source app cannot pop the picker indefinitely.
        guard await self.loopGuard.recordAndCheck(url: url, browserBundleID: LoopGuardKey.picker) else {
            PortalDebugLog.route("router.picker.blockedByLoopGuard", [
                ("url", url.absoluteString),
            ])
            return
        }

        PortalDebugLog.route("router.picker.present", [
            ("url", url.absoluteString),
            ("source", self.describe(sourceApp)),
            ("loadedRules", loadedRules?.count.description ?? "nil"),
        ])
        guard let choice = await pickerCoordinator.presentPicker(for: url, sourceApp: sourceApp) else {
            PortalDebugLog.route("router.picker.dismissed", [("url", url.absoluteString)])
            return
        }
        PortalDebugLog.route("router.picker.choice", [
            ("url", url.absoluteString),
            ("browser", choice.browser.bundleIdentifier),
            ("remember", "\(choice.remember)"),
        ])

        guard await self.loopGuard.recordAndCheck(url: url, browserBundleID: choice.browser.bundleIdentifier) else {
            PortalDebugLog.route("router.picker.choiceBlockedByLoopGuard", [
                ("url", url.absoluteString),
                ("browser", choice.browser.bundleIdentifier),
            ])
            return
        }

        if choice.remember, let host = url.host(), loadedRules != nil {
            await self.persistNewDomainRule(host: host, browserBundleID: choice.browser.bundleIdentifier)
        }

        do {
            try await self.browserLauncher.launch(url, in: choice.browser)
            self.logLaunch(status: "success", url: url, browser: choice.browser.bundleIdentifier)
        } catch {
            self.logLaunch(
                status: "failed",
                url: url,
                browser: choice.browser.bundleIdentifier,
                error: error
            )
            #if DEBUG
                print("[URLRouter] Launch failed for host \(url.host() ?? "<no host>"): \(error)")
            #endif
        }
    }

    private func persistNewDomainRule(host: String, browserBundleID: String) async {
        // Atomic load+append on the store actor so concurrent route(_:) calls
        // never lose each other's writes. If the underlying load throws (e.g.
        // file IO), append throws and we abort rather than clobber rules.json
        // with a truncated snapshot.
        let newRule = Rule.domain(DomainRule(pattern: host, browserBundleID: browserBundleID))
        try? await self.ruleStore.append(newRule)
        PortalDebugLog.route("router.rules.appendDomain", [
            ("host", host),
            ("browser", browserBundleID),
        ])
    }
}

private extension Rule {
    var browserBundleID: String {
        switch self {
        case let .domain(rule): rule.browserBundleID
        case let .sourceApp(rule): rule.browserBundleID
        }
    }
}
