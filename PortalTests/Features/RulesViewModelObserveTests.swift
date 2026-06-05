import Foundation
@testable import Portal
import Testing

@Suite("RulesViewModel observe")
@MainActor
struct RulesViewModelObserveTests {
    private func waitForRules(
        _ viewModel: RulesViewModel,
        satisfying predicate: ([Rule]) -> Bool
    ) async {
        for _ in 0 ..< 200 {
            if predicate(viewModel.rules) { return }
            await Task.yield()
        }
    }

    @Test("startObserving updates rules when store emits")
    func externalSaveUpdatesRules() async {
        let store = ObservableRuleStoreSpy()
        let viewModel = RulesViewModel(store: store)
        await viewModel.load()
        await viewModel.startObserving()

        let rule = Rule.domain(DomainRule(pattern: "live.com", browserBundleID: "com.apple.safari"))
        await store.emit([rule])

        await self.waitForRules(viewModel) { $0 == [rule] }
        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == rule)
    }

    @Test("startObserving reflects multiple emissions")
    func multipleEmissionsReflected() async {
        let store = ObservableRuleStoreSpy()
        let viewModel = RulesViewModel(store: store)
        await viewModel.load()
        await viewModel.startObserving()

        let rule1 = Rule.domain(DomainRule(pattern: "a.com", browserBundleID: "com.apple.safari"))
        let rule2 = Rule.domain(DomainRule(pattern: "b.com", browserBundleID: "com.apple.safari"))

        await store.emit([rule1])
        await self.waitForRules(viewModel) { $0 == [rule1] }
        #expect(viewModel.rules.count == 1)

        await store.emit([rule1, rule2])
        await self.waitForRules(viewModel) { $0 == [rule1, rule2] }
        #expect(viewModel.rules.count == 2)
    }
}

actor ObservableRuleStoreSpy: RuleStore {
    private var continuation: AsyncStream<[Rule]>.Continuation?
    private(set) var savedRuleSets: [[Rule]] = []
    private var initialRules: [Rule] = []

    func load() async throws -> [Rule] {
        self.initialRules
    }

    func save(_ rules: [Rule]) async throws {
        self.savedRuleSets.append(rules)
        self.continuation?.yield(rules)
    }

    func observe() async -> AsyncStream<[Rule]> {
        AsyncStream { cont in
            self.continuation = cont
        }
    }

    func emit(_ rules: [Rule]) {
        self.continuation?.yield(rules)
    }
}
