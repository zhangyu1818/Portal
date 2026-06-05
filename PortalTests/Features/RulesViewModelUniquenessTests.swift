import Foundation
@testable import Portal
import Testing

@MainActor
@Suite("RulesViewModel source-app uniqueness")
struct RulesViewModelUniquenessTests {
    private func makeStore(seed: [Rule] = []) -> InMemoryRuleStore {
        InMemoryRuleStore(seed: seed)
    }

    private func waitForRules(_ viewModel: RulesViewModel, satisfying predicate: ([Rule]) -> Bool) async {
        for _ in 0 ..< 1000 {
            if predicate(viewModel.rules) { return }
            await Task.yield()
        }
    }

    @Test("Adding a duplicate sourceBundleID surfaces a pending replace")
    func duplicateAddSurfacesReplace() async {
        let existing = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.apple.Safari"
        ))
        let store = self.makeStore(seed: [existing])
        let viewModel = RulesViewModel(store: store)
        await viewModel.load()

        let incoming = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome"
        ))
        await viewModel.add(incoming)

        #expect(viewModel.pendingDuplicateReplace != nil)
        #expect(viewModel.pendingDuplicateReplace?.existingRuleID == existing.id)
        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == existing)
    }

    @Test("Confirming replace removes the existing rule and adds the incoming rule")
    func confirmReplace() async {
        let existing = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.apple.Safari"
        ))
        let store = self.makeStore(seed: [existing])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let incoming = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome"
        ))
        await viewModel.add(incoming)
        await viewModel.confirmDuplicateReplace()
        await self.waitForRules(viewModel) { $0.first == incoming }

        #expect(viewModel.pendingDuplicateReplace == nil)
        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == incoming)
    }

    @Test("Cancelling replace clears pending state and leaves rules unchanged")
    func cancelReplace() async {
        let existing = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.apple.Safari"
        ))
        let store = self.makeStore(seed: [existing])
        let viewModel = RulesViewModel(store: store)
        await viewModel.load()

        let incoming = Rule.sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome"
        ))
        await viewModel.add(incoming)
        viewModel.cancelDuplicateReplace()

        #expect(viewModel.pendingDuplicateReplace == nil)
        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == existing)
    }

    @Test("Domain rule with the same pattern is added without prompting")
    func domainDuplicatesNotPrompted() async {
        let existing = Rule.domain(DomainRule(
            pattern: "example.com",
            browserBundleID: "com.apple.Safari"
        ))
        let store = self.makeStore(seed: [existing])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let incoming = Rule.domain(DomainRule(
            pattern: "example.com",
            browserBundleID: "com.google.Chrome"
        ))
        await viewModel.add(incoming)
        await self.waitForRules(viewModel) { $0.count == 2 }

        #expect(viewModel.pendingDuplicateReplace == nil)
        #expect(viewModel.rules.count == 2)
    }
}

private actor InMemoryRuleStore: RuleStore {
    private var rules: [Rule]
    private var continuations: [AsyncStream<[Rule]>.Continuation] = []

    init(seed: [Rule]) {
        self.rules = seed
    }

    func load() async throws -> [Rule] {
        self.rules
    }

    func save(_ rules: [Rule]) async throws {
        self.rules = rules
        for continuation in self.continuations {
            continuation.yield(rules)
        }
    }

    func observe() async -> AsyncStream<[Rule]> {
        AsyncStream { continuation in
            continuation.yield(self.rules)
            self.continuations.append(continuation)
        }
    }
}
