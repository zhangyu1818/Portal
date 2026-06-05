import Foundation
@testable import Portal

actor MockRuleStore: RuleStore {
    private var rules: [Rule]
    private let loadError: (any Error)?
    private(set) var savedRuleSets: [[Rule]] = []
    private var continuations: [AsyncStream<[Rule]>.Continuation] = []

    init(rules: [Rule] = [], loadError: (any Error)? = nil) {
        self.rules = rules
        self.loadError = loadError
    }

    func load() async throws -> [Rule] {
        if let loadError {
            throw loadError
        }
        return self.rules
    }

    func save(_ rules: [Rule]) async throws {
        self.savedRuleSets.append(rules)
        self.rules = rules
        for continuation in self.continuations {
            continuation.yield(rules)
        }
    }

    func observe() async -> AsyncStream<[Rule]> {
        AsyncStream { continuation in
            self.continuations.append(continuation)
            continuation.yield(self.rules)
        }
    }
}

actor MockBrowserLauncher: BrowserLauncher {
    struct Call {
        let url: URL
        let browser: Browser
    }

    private(set) var recordedCalls: [Call] = []
    private let error: (any Error)?

    init(throwing error: (any Error)? = nil) {
        self.error = error
    }

    func launch(_ url: URL, in browser: Browser) async throws {
        if let error {
            throw error
        }
        self.recordedCalls.append(Call(url: url, browser: browser))
    }
}

actor MockBrowserRegistry: BrowserRegistry {
    private let browsers: [Browser]
    private(set) var refreshCallCount: Int = 0
    private var continuations: [AsyncStream<[Browser]>.Continuation] = []

    init(browsers: [Browser] = []) {
        self.browsers = browsers
    }

    func current() async -> [Browser] {
        self.browsers
    }

    func observe() async -> AsyncStream<[Browser]> {
        AsyncStream { continuation in
            self.continuations.append(continuation)
        }
    }

    func refresh() async {
        self.refreshCallCount += 1
    }

    func emit(_ browsers: [Browser]) {
        for continuation in self.continuations {
            continuation.yield(browsers)
        }
    }
}
