import Foundation
@testable import Portal
import Testing

@MainActor
@Suite("BrowsersViewModel.displayName(forBundleID:)")
struct BrowsersViewModelDisplayNameTests {
    @Test("Returns displayName when bundle id is present in snapshot")
    func returnsDisplayName() async {
        let registry = StubBrowserRegistry(initial: [
            Browser(
                bundleIdentifier: "com.apple.Safari",
                displayName: "Safari",
                bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
            ),
        ])
        let viewModel = BrowsersViewModel(registry: registry)
        await viewModel.load()
        #expect(viewModel.displayName(forBundleID: "com.apple.Safari") == "Safari")
    }

    @Test("Returns nil when bundle id is not present")
    func returnsNilWhenAbsent() async {
        let registry = StubBrowserRegistry(initial: [])
        let viewModel = BrowsersViewModel(registry: registry)
        await viewModel.load()
        #expect(viewModel.displayName(forBundleID: "com.unknown") == nil)
    }
}

private actor StubBrowserRegistry: BrowserRegistry {
    private var browsers: [Browser]

    init(initial: [Browser]) {
        self.browsers = initial
    }

    func current() async -> [Browser] {
        self.browsers
    }

    func observe() async -> AsyncStream<[Browser]> {
        AsyncStream { continuation in
            continuation.yield(self.browsers)
            continuation.finish()
        }
    }

    func refresh() async {}
}
