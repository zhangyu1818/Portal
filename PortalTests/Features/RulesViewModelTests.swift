import Foundation
@testable import Portal
import Testing

@Suite("RulesViewModel")
@MainActor
struct RulesViewModelTests {
    private func makeDomainRule(pattern: String = "example.com") -> Rule {
        .domain(DomainRule(
            pattern: pattern,
            browserBundleID: "com.apple.safari"
        ))
    }

    private func makeSourceAppRule(bundleID: String = "com.tinyspeck.slackmacgap") -> Rule {
        .sourceApp(SourceAppRule(
            sourceBundleID: bundleID,
            browserBundleID: "com.google.Chrome"
        ))
    }

    private func waitForRules(_ viewModel: RulesViewModel, satisfying predicate: ([Rule]) -> Bool) async {
        for _ in 0 ..< 1000 {
            if predicate(viewModel.rules) { return }
            await Task.yield()
        }
    }

    @Test("addAppendsRuleAndSaves")
    func addAppendsRuleAndSaves() async {
        let store = MockRuleStore(rules: [])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let rule = self.makeDomainRule()
        await viewModel.add(rule)
        await self.waitForRules(viewModel) { $0.contains(rule) }

        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == rule)
        let saves = await store.savedRuleSets
        #expect(saves.count == 1)
        #expect(saves.first?.first == rule)
    }

    @Test("updateReplacesRuleByID")
    func updateReplacesRuleByID() async throws {
        let original = self.makeDomainRule(pattern: "original.com")
        let store = MockRuleStore(rules: [original])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let updated = Rule.domain(DomainRule(
            id: original.id,
            pattern: "updated.com",
            browserBundleID: "com.apple.safari"
        ))
        await viewModel.update(updated)
        await self.waitForRules(viewModel) { rules in
            if case let .domain(inner) = rules.first {
                return inner.pattern == "updated.com"
            }
            return false
        }

        #expect(viewModel.rules.count == 1)
        if case let .domain(inner) = viewModel.rules.first {
            #expect(inner.pattern == "updated.com")
        } else {
            Issue.record("expected domain rule")
        }
        let saves = await store.savedRuleSets
        let lastSave = try #require(saves.last)
        let firstRule = try #require(lastSave.first)
        guard case let .domain(savedInner) = firstRule else {
            Issue.record("expected domain rule in saved set")
            return
        }
        #expect(savedInner.pattern == "updated.com")
    }

    @Test("removeAtIndicesRemovesAndSaves")
    func removeAtIndicesRemovesAndSaves() async throws {
        let ruleA = self.makeDomainRule(pattern: "a.com")
        let ruleB = self.makeDomainRule(pattern: "b.com")
        let store = MockRuleStore(rules: [ruleA, ruleB])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        await viewModel.remove(at: IndexSet(integer: 0))
        await self.waitForRules(viewModel) { $0 == [ruleB] }

        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first == ruleB)
        let saves = await store.savedRuleSets
        let lastSave = try #require(saves.last)
        #expect(!lastSave.contains(ruleA))
        #expect(lastSave.contains(ruleB))
    }

    @Test("moveReordersAndSaves")
    func moveReordersAndSaves() async throws {
        let ruleA = self.makeDomainRule(pattern: "a.com")
        let ruleB = self.makeDomainRule(pattern: "b.com")
        let ruleC = self.makeDomainRule(pattern: "c.com")
        let store = MockRuleStore(rules: [ruleA, ruleB, ruleC])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        await viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        await self.waitForRules(viewModel) { $0 == [ruleB, ruleC, ruleA] }

        #expect(viewModel.rules.count == 3)
        #expect(viewModel.rules[0] == ruleB)
        #expect(viewModel.rules[1] == ruleC)
        #expect(viewModel.rules[2] == ruleA)
        let saves = await store.savedRuleSets
        let lastSave = try #require(saves.last)
        #expect(lastSave == [ruleB, ruleC, ruleA])
    }

    @Test("loadFromStoreInitializesRules")
    func loadFromStoreInitializesRules() async {
        let rule1 = self.makeDomainRule(pattern: "first.com")
        let rule2 = self.makeSourceAppRule()
        let store = MockRuleStore(rules: [rule1, rule2])
        let viewModel = RulesViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.rules.count == 2)
        #expect(viewModel.rules[0] == rule1)
        #expect(viewModel.rules[1] == rule2)
    }

    @Test("toggleEnabledUpdatesAndSaves")
    func toggleEnabledUpdatesAndSaves() async throws {
        let rule = Rule.domain(DomainRule(
            pattern: "example.com",
            browserBundleID: "com.apple.safari",
            enabled: true
        ))
        let store = MockRuleStore(rules: [rule])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        await viewModel.update(rule.withEnabled(false))
        await self.waitForRules(viewModel) { $0.first?.isEnabled == false }

        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first?.isEnabled == false)
        let saves = await store.savedRuleSets
        let lastSave = try #require(saves.last)
        let savedRule = try #require(lastSave.first)
        #expect(savedRule.isEnabled == false)
    }

    @Test("concurrent add calls preserve all rules")
    func concurrentAddCallsPreserveAllRules() async {
        let store = MockRuleStore(rules: [])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let ruleA = self.makeDomainRule(pattern: "a.com")
        let ruleB = self.makeDomainRule(pattern: "b.com")

        async let firstAdd: Void = viewModel.add(ruleA)
        async let secondAdd: Void = viewModel.add(ruleB)
        _ = await (firstAdd, secondAdd)
        await self.waitForRules(viewModel) { $0.contains(ruleA) && $0.contains(ruleB) }

        let saves = await store.savedRuleSets
        let finalSave = saves.last ?? []
        #expect(finalSave.contains(ruleA))
        #expect(finalSave.contains(ruleB))
        #expect(viewModel.rules.contains(ruleA))
        #expect(viewModel.rules.contains(ruleB))
    }

    @Test("update with non-existent ID preserves the existing rules")
    func updateNonexistentIDIsNoOp() async {
        let original = self.makeDomainRule(pattern: "original.com")
        let store = MockRuleStore(rules: [original])
        let viewModel = RulesViewModel(store: store)
        await viewModel.startObserving()
        await viewModel.load()

        let stranger = self.makeDomainRule(pattern: "unknown.com")
        await viewModel.update(stranger)
        await self.waitForRules(viewModel) { $0 == [original] }

        #expect(viewModel.rules == [original])
        let saves = await store.savedRuleSets
        let lastSave = saves.last ?? []
        #expect(lastSave == [original])
    }
}
