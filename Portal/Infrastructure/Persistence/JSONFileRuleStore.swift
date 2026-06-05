import Foundation

public actor JSONFileRuleStore: RuleStore {
    private nonisolated static let fileName = "rules.json"

    private let directory: URL
    private var cachedRules: [Rule]?
    private var continuations: [Int: AsyncStream<[Rule]>.Continuation] = [:]
    private var nextID: Int = 0

    public init(directory: URL) {
        self.directory = directory
    }

    public init() throws {
        self.directory = try .applicationSupport
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    public func load() async throws -> [Rule] {
        try self.loadSync()
    }

    public func save(_ rules: [Rule]) async throws {
        try self.saveSync(rules)
        self.cachedRules = rules
        self.fanOut(rules)
    }

    public func append(_ rule: Rule) async throws {
        // Override the protocol default so load+save runs as a single
        // synchronous span on this actor: concurrent appends cannot read the
        // same snapshot and overwrite each other.
        let existing = try self.loadSync()
        let updated = existing + [rule]
        try self.saveSync(updated)
        self.cachedRules = updated
        self.fanOut(updated)
    }

    private func loadSync() throws -> [Rule] {
        let fileURL = self.directory.appending(path: Self.fileName)
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            self.cachedRules = []
            return []
        } catch {
            throw RuleStoreError.ioFailed(underlying: error)
        }
        do {
            let rules = try Self.makeDecoder().decode([Rule].self, from: data)
            self.cachedRules = rules
            return rules
        } catch {
            throw RuleStoreError.fileCorrupted(underlying: error)
        }
    }

    private func saveSync(_ rules: [Rule]) throws {
        do {
            try FileManager.default.createDirectory(
                at: self.directory,
                withIntermediateDirectories: true
            )
            let data = try Self.makeEncoder().encode(rules)
            let fileURL = self.directory.appending(path: Self.fileName)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw RuleStoreError.ioFailed(underlying: error)
        }
    }

    public func observe() async -> AsyncStream<[Rule]> {
        AsyncStream { continuation in
            let id = self.nextID
            self.nextID &+= 1
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.removeContinuation(id: id) }
            }
            if let cached = cachedRules {
                continuation.yield(cached)
            } else {
                // No cached snapshot yet: proactively load so subscribers that
                // call observe() before load() still receive an initial value
                // without waiting for a future save().
                Task { [weak self] in
                    guard let self else { return }
                    await self.yieldInitialLoad(to: id)
                }
            }
        }
    }

    private func yieldInitialLoad(to id: Int) async {
        // Avoid load() if a save() landed first and already populated the
        // cache (and fanned out to this continuation).
        if self.cachedRules != nil { return }
        _ = try? await self.load()
        guard let continuation = self.continuations[id], let rules = self.cachedRules else { return }
        continuation.yield(rules)
    }

    private func removeContinuation(id: Int) {
        self.continuations.removeValue(forKey: id)
    }

    private func fanOut(_ rules: [Rule]) {
        for continuation in self.continuations.values {
            continuation.yield(rules)
        }
    }

    private nonisolated static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private nonisolated static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}
