import Foundation
@testable import Portal
import Testing

@Suite("BrowsersViewModel")
@MainActor
struct BrowsersViewModelTests {
    private func makeBrowser(_ id: String) -> Browser {
        Browser(
            bundleIdentifier: id,
            displayName: id,
            bundleURL: URL(filePath: "/Applications/\(id).app")
        )
    }

    @Test("loadFromRegistryPopulatesBrowsers")
    func loadFromRegistryPopulatesBrowsers() async {
        let safari = self.makeBrowser("com.apple.safari")
        let chrome = self.makeBrowser("com.google.Chrome")
        let registry = MockBrowserRegistry(browsers: [safari, chrome])
        let viewModel = BrowsersViewModel(registry: registry)

        await viewModel.load()

        #expect(viewModel.browsers.count == 2)
        #expect(viewModel.browsers.contains(safari))
        #expect(viewModel.browsers.contains(chrome))
    }

    @Test("loadTriggersRegistryRefresh")
    func loadTriggersRegistryRefresh() async {
        let registry = MockBrowserRegistry(browsers: [])
        let viewModel = BrowsersViewModel(registry: registry)

        await viewModel.load()

        let refreshCount = await registry.refreshCallCount
        #expect(refreshCount == 1)
    }

    @Test("loadReadsFallbackBrowserSelection")
    func loadReadsFallbackBrowserSelection() async {
        let fallbackStore = MockFallbackBrowserPreferenceStore(bundleID: "com.apple.safari")
        let viewModel = BrowsersViewModel(
            registry: MockBrowserRegistry(browsers: []),
            fallbackPreferenceStore: fallbackStore
        )

        await viewModel.load()

        #expect(viewModel.fallbackBrowserBundleID == "com.apple.safari")
    }

    @Test("setFallbackBrowserSelectionPersistsAndUpdatesState")
    func setFallbackBrowserSelectionPersistsAndUpdatesState() async {
        let fallbackStore = MockFallbackBrowserPreferenceStore()
        let viewModel = BrowsersViewModel(
            registry: MockBrowserRegistry(browsers: []),
            fallbackPreferenceStore: fallbackStore
        )

        await viewModel.setFallbackBrowserBundleID("com.google.Chrome")

        #expect(viewModel.fallbackBrowserBundleID == "com.google.Chrome")
        #expect(await fallbackStore.fallbackBrowserBundleID() == "com.google.Chrome")

        await viewModel.setFallbackBrowserBundleID(nil)

        #expect(viewModel.fallbackBrowserBundleID == nil)
        #expect(await fallbackStore.fallbackBrowserBundleID() == nil)
    }

    @Test("observeRegistryUpdatesBrowsers")
    func observeRegistryUpdatesBrowsers() async {
        let registry = MockBrowserRegistry(browsers: [])
        let viewModel = BrowsersViewModel(registry: registry)
        await viewModel.load()
        await viewModel.startObserving()

        let safari = self.makeBrowser("com.apple.safari")
        let chrome = self.makeBrowser("com.google.Chrome")
        await registry.emit([safari, chrome])

        for _ in 0 ..< 200 {
            if viewModel.browsers.count == 2 { break }
            await Task.yield()
        }
        #expect(viewModel.browsers == [safari, chrome])
    }
}
