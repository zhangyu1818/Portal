import Foundation
@testable import Portal
import Testing

@Suite("JSONFileRuleStore")
final class JSONFileRuleStoreTests {
    private let directory: URL
    private let store: JSONFileRuleStore

    init() throws {
        self.directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        self.store = JSONFileRuleStore(directory: self.directory)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeDomainRule() -> Rule {
        .domain(DomainRule(
            pattern: "example.com",
            browserBundleID: "com.apple.safari",
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        ))
    }

    private func makeSourceAppRule() -> Rule {
        .sourceApp(SourceAppRule(
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome",
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        ))
    }

    @Test("load from missing file returns empty array")
    func loadFromMissingFileReturnsEmpty() async throws {
        let rules = try await store.load()
        #expect(rules.isEmpty)
    }

    @Test("save then load round-trips both rule types")
    func saveThenLoadRoundTrip() async throws {
        let rules: [Rule] = [makeDomainRule(), makeSourceAppRule()]
        try await store.save(rules)

        let freshStore = JSONFileRuleStore(directory: directory)
        let loaded = try await freshStore.load()
        #expect(loaded == rules)
    }

    @Test("save creates directory if missing")
    func saveCreatesDirectoryIfMissing() async throws {
        let nested = self.directory.appending(path: "subdir/\(UUID().uuidString)")
        let nestedStore = JSONFileRuleStore(directory: nested)
        try await nestedStore.save([self.makeDomainRule()])
        #expect(FileManager.default.fileExists(atPath: nested.path))
    }

    @Test("load throws ioFailed when rules.json is a directory")
    func loadIOErrorThrowsIOFailed() async throws {
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        let rulesPath = self.directory.appending(path: "rules.json")
        try FileManager.default.createDirectory(at: rulesPath, withIntermediateDirectories: true)

        var caught: RuleStoreError?
        do {
            _ = try await self.store.load()
        } catch let error as RuleStoreError {
            caught = error
        }
        let error = try #require(caught)
        if case .ioFailed = error {
        } else {
            Issue.record("expected .ioFailed, got \(error)")
        }
    }

    @Test("malformed JSON throws fileCorrupted")
    func malformedJSONThrowsFileCorrupted() async throws {
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        try Data("not valid json".utf8).write(to: self.directory.appending(path: "rules.json"))

        var caught: RuleStoreError?
        do {
            _ = try await self.store.load()
        } catch let error as RuleStoreError {
            caught = error
        }
        let error = try #require(caught)
        if case .fileCorrupted = error {
        } else {
            Issue.record("expected .fileCorrupted, got \(error)")
        }
    }

    @Test("save writes atomically, no leftover temp files")
    func saveWritesAtomically() async throws {
        try await self.store.save([self.makeDomainRule()])
        let contents = try FileManager.default.contentsOfDirectory(atPath: self.directory.path)
        #expect(contents.contains("rules.json"))
        let tempFiles = contents.filter { $0.hasSuffix(".tmp") }
        #expect(tempFiles.isEmpty)
    }

    @Test("observe emits current state immediately after load")
    func observeEmitsCurrentStateImmediatelyAfterLoad() async throws {
        _ = try await self.store.load()
        let stream = await store.observe()
        var iterator = stream.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value != nil)
        let rules = try #require(value)
        #expect(rules.isEmpty)
    }

    @Test("observeBeforeLoadEventuallyEmits — subscribe before load, expect first emission")
    func observeBeforeLoadEventuallyEmits() async throws {
        let stream = await store.observe()
        var iterator = stream.makeAsyncIterator()
        let value = await iterator.next()
        let rules = try #require(value)
        #expect(rules.isEmpty)
    }

    @Test("observe emits after subsequent save")
    func observeEmitsAfterSubsequentSave() async throws {
        let stream = await store.observe()
        var iter = stream.makeAsyncIterator()

        // Drain the initial emission (empty state from proactive load).
        _ = await iter.next()

        let rule1 = self.makeDomainRule()
        try await self.store.save([rule1])
        let first = try #require(await iter.next())
        #expect(first.count == 1)

        let rule2 = self.makeSourceAppRule()
        try await self.store.save([rule1, rule2])
        let second = try #require(await iter.next())
        #expect(second.count == 2)
    }

    @Test("multiple observers each receive save updates")
    func multipleObserversReceiveSameUpdates() async throws {
        let stream1 = await store.observe()
        let stream2 = await store.observe()

        var iter1 = stream1.makeAsyncIterator()
        var iter2 = stream2.makeAsyncIterator()

        // Drain initial emissions (empty state from proactive load).
        _ = await iter1.next()
        _ = await iter2.next()

        let rule = self.makeDomainRule()
        try await self.store.save([rule])

        let rules1 = try #require(await iter1.next())
        let rules2 = try #require(await iter2.next())
        #expect(rules1.contains(rule))
        #expect(rules2.contains(rule))
    }

    @Test("concurrent saves produce no corruption")
    func concurrentSavesProduceLastWriteWins() async throws {
        let rules1: [Rule] = [makeDomainRule()]
        let rules2: [Rule] = [makeSourceAppRule()]

        async let save1: Void = self.store.save(rules1)
        async let save2: Void = self.store.save(rules2)
        try await save1
        try await save2

        let loaded = try await store.load()
        #expect(loaded == rules1 || loaded == rules2)

        let fileURL = self.directory.appending(path: "rules.json")
        let data = try Data(contentsOf: fileURL)
        #expect(!data.isEmpty)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        _ = try decoder.decode([Rule].self, from: data)
    }
}
