import Foundation

public enum RuleStoreError: Error, Sendable {
    case fileCorrupted(underlying: any Error)
    case ioFailed(underlying: any Error)
}

extension RuleStoreError: Equatable {
    public static func == (lhs: RuleStoreError, rhs: RuleStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.fileCorrupted, .fileCorrupted): true
        case (.ioFailed, .ioFailed): true
        default: false
        }
    }
}

public protocol RuleStore: Sendable {
    func load() async throws -> [Rule]
    func save(_ rules: [Rule]) async throws
    func append(_ rule: Rule) async throws
    func observe() async -> AsyncStream<[Rule]>
}

public extension RuleStore {
    func append(_ rule: Rule) async throws {
        let existing = try await self.load()
        try await self.save(existing + [rule])
    }
}
