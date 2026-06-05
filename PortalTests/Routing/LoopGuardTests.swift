import Foundation
import os
@testable import Portal
import Testing

@Suite("LoopGuard")
struct LoopGuardTests {
    private let testURL: URL
    private let browserID = "com.apple.safari"
    private let otherBrowserID = "com.google.chrome"

    init() throws {
        self.testURL = try #require(URL(string: "https://example.com"))
    }

    @Test("firstTwoAllowedThirdBlocked — threshold=3, 1st and 2nd allowed, 3rd blocked")
    func firstTwoAllowedThirdBlocked() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        #expect(await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID))
        #expect(await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID))
        let third = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(!third)
    }

    @Test("exactlyAtThresholdBlocks — count == threshold returns false (blocked)")
    func exactlyAtThresholdBlocks() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        let third = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(!third)
    }

    @Test("exceedingThresholdBlocks — 4th call also returns false")
    func exceedingThresholdBlocks() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        let result = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(!result)
    }

    @Test("differentURLsDoNotInterfere — url A reaches threshold; url B's first call still allowed")
    func differentURLsDoNotInterfere() async throws {
        let urlB = try #require(URL(string: "https://other.com"))
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(await loopGuard.recordAndCheck(url: urlB, browserBundleID: self.browserID))
    }

    @Test("differentBrowsersDoNotInterfere — same url different browser IDs, distinct counters")
    func differentBrowsersDoNotInterfere() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.otherBrowserID))
    }

    @Test("oldEntriesEvictedAfterWindow — record up to threshold, advance clock past window, next allowed")
    func oldEntriesEvictedAfterWindow() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        clock.advance(by: .seconds(2))
        let result = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(result)
    }

    @Test("thresholdRespectsConfigured — threshold=1, first call already blocks")
    func thresholdRespectsConfigured() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 1, window: .seconds(1), now: { clock.now })
        let result = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        #expect(!result)
    }

    @Test("exactlyAtWindowBoundary — entry at exactly cutoff is pruned (filter uses >, not >=)")
    func exactlyAtWindowBoundary() async {
        let clock = MockClock()
        let loopGuard = LoopGuard(threshold: 3, window: .seconds(1), now: { clock.now })
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        _ = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        clock.advance(by: .seconds(1))
        let result = await loopGuard.recordAndCheck(url: self.testURL, browserBundleID: self.browserID)
        // At exactly the window boundary, prior entries are pruned (timestamp > cutoff is false),
        // so this is the 1st entry of the new window and is allowed.
        #expect(result)
    }
}

private final class MockClock: Sendable {
    private let elapsed = OSAllocatedUnfairLock<Duration>(initialState: .zero)
    private let base: ContinuousClock.Instant

    init() {
        self.base = ContinuousClock.now
    }

    nonisolated var now: ContinuousClock.Instant {
        self.base + self.elapsed.withLock { $0 }
    }

    nonisolated func advance(by duration: Duration) {
        self.elapsed.withLock { $0 += duration }
    }
}
