import Foundation

public protocol LoopGuardProtocol: Sendable {
    func recordAndCheck(url: URL, browserBundleID: String) async -> Bool
}

public enum LoopGuardKey {
    /// Sentinel bundle identifier used when guarding the picker presentation
    /// itself (no destination browser is known yet).
    public static let picker = "<picker>"
}

public actor LoopGuard: LoopGuardProtocol {
    private struct Entry {
        let url: URL
        let bundleID: String
        let timestamp: ContinuousClock.Instant
    }

    private let threshold: Int
    private let window: Duration
    private let now: @Sendable () -> ContinuousClock.Instant
    private var entries: [Entry] = []

    public init(
        threshold: Int = 3,
        window: Duration = .seconds(1),
        now: @Sendable @escaping () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.threshold = threshold
        self.window = window
        self.now = now
    }

    public func recordAndCheck(url: URL, browserBundleID: String) async -> Bool {
        let current = self.now()
        let cutoff = current - self.window
        self.entries = self.entries.filter { $0.timestamp > cutoff }
        self.entries.append(Entry(url: url, bundleID: browserBundleID, timestamp: current))
        let count = self.entries.filter { $0.url == url && $0.bundleID == browserBundleID }.count
        return count < self.threshold
    }
}
