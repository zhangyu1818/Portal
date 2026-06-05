import Foundation
import Observation

@MainActor
@Observable
final class BrowsersViewModel {
    private(set) var browsers: [Browser] = []
    private(set) var fallbackBrowserBundleID: String?
    private let registry: any BrowserRegistry
    private let fallbackPreferenceStore: any FallbackBrowserPreferenceStore
    private(set) var observeTask: Task<Void, Never>?

    init(
        registry: any BrowserRegistry,
        fallbackPreferenceStore: any FallbackBrowserPreferenceStore = UserDefaultsFallbackStore()
    ) {
        self.registry = registry
        self.fallbackPreferenceStore = fallbackPreferenceStore
    }

    func load() async {
        await self.registry.refresh()
        self.browsers = await self.registry.current()
        self.fallbackBrowserBundleID = await self.fallbackPreferenceStore.fallbackBrowserBundleID()
    }

    func setFallbackBrowserBundleID(_ bundleID: String?) async {
        await self.fallbackPreferenceStore.setFallbackBrowserBundleID(bundleID)
        self.fallbackBrowserBundleID = await self.fallbackPreferenceStore.fallbackBrowserBundleID()
    }

    func startObserving() async {
        self.observeTask?.cancel()
        let stream = await self.registry.observe()
        self.observeTask = Task { [weak self] in
            for await updated in stream {
                guard let self, !Task.isCancelled else { return }
                self.browsers = updated
            }
        }
    }

    func stopObserving() {
        self.observeTask?.cancel()
        self.observeTask = nil
    }

    func displayName(forBundleID bundleID: String) -> String? {
        self.browsers.first(where: { $0.bundleIdentifier == bundleID })?.displayName
    }
}
