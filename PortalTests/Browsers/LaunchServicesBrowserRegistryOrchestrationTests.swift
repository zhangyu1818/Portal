import Foundation
@testable import Portal
import Testing

private func makeBrowser(id: String) -> Browser {
    Browser(bundleIdentifier: id, displayName: id, bundleURL: URL(filePath: "/\(id)"))
}

private actor ScriptedScanner {
    private var responses: [[Browser]]
    private var index = 0

    init(responses: [[Browser]]) {
        self.responses = responses
    }

    func next() -> [Browser] {
        guard self.index < self.responses.count else { return self.responses.last ?? [] }
        defer { index += 1 }
        return self.responses[self.index]
    }
}

@Suite("LaunchServicesBrowserRegistry orchestration")
struct RegistryOrchestrationTests {
    @Test("refresh emits when content changes")
    func refreshEmitsOnChange() async {
        let first = [makeBrowser(id: "aaa")]
        let second = [makeBrowser(id: "bbb")]
        let scripted = ScriptedScanner(responses: [first, second])
        let registry = LaunchServicesBrowserRegistry(scanner: { await scripted.next() })

        let stream = await registry.observe()
        var iterator = stream.makeAsyncIterator()

        await registry.refresh()
        let result1 = await iterator.next()
        #expect(result1 == first)

        await registry.refresh()
        let result2 = await iterator.next()
        #expect(result2 == second)
    }

    @Test("refresh does NOT emit when content is identical")
    func refreshSkipsWhenSame() async {
        let browsers = [makeBrowser(id: "aaa")]
        let updated = [makeBrowser(id: "bbb")]
        let scripted = ScriptedScanner(responses: [browsers, browsers, updated])
        let registry = LaunchServicesBrowserRegistry(
            scanner: { await scripted.next() },
            observeWorkspace: false
        )

        let stream = await registry.observe()
        // Drive the scripted scanner: first refresh emits `browsers`, second is
        // identical (must be skipped), third emits `updated`. If the registry
        // wrongly emits on the duplicate, the iterator's second value would be
        // `browsers` instead of `updated`.
        let collector = Task { () -> [[Browser]] in
            var collected: [[Browser]] = []
            for await value in stream.prefix(2) {
                collected.append(value)
            }
            return collected
        }

        await registry.refresh()
        await registry.refresh()
        await registry.refresh()

        let collected = await collector.value
        #expect(collected == [browsers, updated])
    }

    @Test("observe yields current cache on subscribe")
    func observeYieldsCurrent() async {
        let browsers = [makeBrowser(id: "cached")]
        let scripted = ScriptedScanner(responses: [browsers])
        let registry = LaunchServicesBrowserRegistry(scanner: { await scripted.next() })

        await registry.refresh()

        let stream = await registry.observe()
        var iterator = stream.makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == browsers)
    }

    @Test("multiple observers all receive the same update")
    func multipleObserversReceiveUpdates() async {
        let initial = [makeBrowser(id: "xxx")]
        let updated = [makeBrowser(id: "yyy")]
        let scripted = ScriptedScanner(responses: [initial, updated])
        let registry = LaunchServicesBrowserRegistry(scanner: { await scripted.next() })

        await registry.refresh()

        let stream1 = await registry.observe()
        let stream2 = await registry.observe()
        var it1 = stream1.makeAsyncIterator()
        var it2 = stream2.makeAsyncIterator()

        let cached1 = await it1.next()
        let cached2 = await it2.next()
        #expect(cached1 == initial)
        #expect(cached2 == initial)

        await registry.refresh()

        let next1 = await it1.next()
        let next2 = await it2.next()
        #expect(next1 == updated)
        #expect(next2 == updated)
    }
}
