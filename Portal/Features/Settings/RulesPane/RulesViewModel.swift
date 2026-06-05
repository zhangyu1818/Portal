import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class RulesViewModel {
    struct PendingDuplicateReplace: Equatable {
        let existingRuleID: UUID
        let incomingRule: Rule
    }

    private(set) var rules: [Rule] = []
    private(set) var pendingDuplicateReplace: PendingDuplicateReplace?
    private let store: any RuleStore
    private(set) var observeTask: Task<Void, Never>?
    private var pendingEdit: Task<Void, Never>?

    init(store: any RuleStore) {
        self.store = store
    }

    func load() async {
        guard let loaded = try? await store.load() else { return }
        self.rules = loaded
    }

    func startObserving() async {
        self.observeTask?.cancel()
        let stream = await store.observe()
        self.observeTask = Task { [weak self] in
            for await updatedRules in stream {
                guard let self, !Task.isCancelled else { return }
                self.rules = updatedRules
            }
        }
    }

    func stopObserving() {
        self.observeTask?.cancel()
        self.observeTask = nil
    }

    func add(_ rule: Rule) async {
        if case let .sourceApp(incoming) = rule {
            let existing = self.rules.first { existingRule in
                guard case let .sourceApp(inner) = existingRule else { return false }
                return inner.sourceBundleID == incoming.sourceBundleID
            }
            if let existing {
                self.pendingDuplicateReplace = PendingDuplicateReplace(existingRuleID: existing.id, incomingRule: rule)
                return
            }
        }
        await self.serialEdit { current in
            current + [rule]
        }
    }

    func confirmDuplicateReplace() async {
        guard let pending = self.pendingDuplicateReplace else { return }
        self.pendingDuplicateReplace = nil
        await self.serialEdit { current in
            current.filter { $0.id != pending.existingRuleID } + [pending.incomingRule]
        }
    }

    func cancelDuplicateReplace() {
        self.pendingDuplicateReplace = nil
    }

    func update(_ rule: Rule) async {
        await self.serialEdit { current in
            guard let index = current.firstIndex(where: { $0.id == rule.id }) else {
                return current
            }
            var updated = current
            updated[index] = rule
            return updated
        }
    }

    func remove(at indices: IndexSet) async {
        await self.serialEdit { current in
            var updated = current
            updated.remove(atOffsets: indices)
            return updated
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) async {
        await self.serialEdit { current in
            var updated = current
            updated.move(fromOffsets: source, toOffset: destination)
            return updated
        }
    }

    private func serialEdit(_ transform: @escaping ([Rule]) -> [Rule]) async {
        let previous = self.pendingEdit
        let task = Task { @MainActor [weak self] in
            await previous?.value
            guard let self else { return }
            await self.applyEdit(transform)
        }
        self.pendingEdit = task
        await task.value
    }

    private func applyEdit(_ transform: ([Rule]) -> [Rule]) async {
        let loaded = try? await self.store.load()
        let current = loaded ?? self.rules
        let next = transform(current)
        try? await self.store.save(next)
    }
}
