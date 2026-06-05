import Foundation
@testable import Portal

struct MockRuleEngine: RuleEngine {
    let match: RuleMatch
    let perURL: [URL: RuleMatch]

    init(match: RuleMatch, perURL: [URL: RuleMatch] = [:]) {
        self.match = match
        self.perURL = perURL
    }

    func evaluate(_ input: RoutingInput, against _: [Rule]) -> RuleMatch {
        self.perURL[input.url] ?? self.match
    }
}

struct MockSourceAppDetector: SourceAppDetector {
    let source: SourceApp?
    var pidSources: [pid_t: SourceApp] = [:]

    func currentSource() async -> SourceApp? {
        self.source
    }

    func source(forSenderPID pid: pid_t) async -> SourceApp? {
        self.pidSources[pid]
    }
}

actor MockFallbackBrowserPreferenceStore: FallbackBrowserPreferenceStore {
    private var bundleID: String?

    init(bundleID: String? = nil) {
        self.bundleID = bundleID
    }

    func fallbackBrowserBundleID() async -> String? {
        self.bundleID
    }

    func setFallbackBrowserBundleID(_ bundleID: String?) async {
        self.bundleID = bundleID
    }
}

actor MockLoopGuard: LoopGuardProtocol {
    private let allow: Bool

    init(allow: Bool) {
        self.allow = allow
    }

    func recordAndCheck(url _: URL, browserBundleID _: String) async -> Bool {
        self.allow
    }
}

actor MockPickerCoordinator: PickerCoordinator {
    private(set) var presentedURLs: [URL] = []
    private let choice: PickerChoice?

    init(choice: PickerChoice?) {
        self.choice = choice
    }

    func presentPicker(for url: URL, sourceApp _: SourceApp?) async -> PickerChoice? {
        self.presentedURLs.append(url)
        return self.choice
    }
}

struct RouterComponents {
    let router: URLRouter
    let launcher: MockBrowserLauncher
    let picker: MockPickerCoordinator
    let ruleStore: MockRuleStore
}

@MainActor
func makeRouter(
    rules: [Rule] = [],
    ruleMatch: RuleMatch = .noMatch,
    perURLMatches: [URL: RuleMatch] = [:],
    sourceApp: SourceApp? = nil,
    browsers: [Browser] = [],
    loopGuardAllow: Bool = true,
    pickerChoice: PickerChoice? = nil,
    launchError: (any Error)? = nil,
    loadError: (any Error)? = nil,
    fallbackBrowserBundleID: String? = nil
) -> RouterComponents {
    let ruleStore = MockRuleStore(rules: rules, loadError: loadError)
    let ruleEngine = MockRuleEngine(match: ruleMatch, perURL: perURLMatches)
    let sourceAppDetector = MockSourceAppDetector(source: sourceApp)
    let launcher = MockBrowserLauncher(throwing: launchError)
    let registry = MockBrowserRegistry(browsers: browsers)
    let loopGuard = MockLoopGuard(allow: loopGuardAllow)
    let picker = MockPickerCoordinator(choice: pickerChoice)
    let router = URLRouter(
        ruleStore: ruleStore,
        ruleEngine: ruleEngine,
        sourceAppDetector: sourceAppDetector,
        browserLauncher: launcher,
        browserRegistry: registry,
        loopGuard: loopGuard,
        pickerCoordinator: picker,
        fallbackPreferenceStore: MockFallbackBrowserPreferenceStore(bundleID: fallbackBrowserBundleID)
    )
    return RouterComponents(router: router, launcher: launcher, picker: picker, ruleStore: ruleStore)
}
