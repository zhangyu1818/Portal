import AppKit
@testable import Portal
import Testing

@Suite("MenuBarMenuView")
@MainActor
struct MenuBarMenuViewTests {
    @Test("menu content can be constructed without invoking actions")
    func menuContentCanBeConstructedWithoutInvokingActions() {
        var didQuit = false
        let service = MockDefaultBrowserService(status: .isDefault)

        _ = MenuBarMenuView(defaultBrowserService: service) {
            didQuit = true
        }

        #expect(didQuit == false)
    }

    @Test("menu inserts update item before quit section when provider returns one")
    func menuInsertsUpdateItemBeforeQuitSection() throws {
        let provider = StubSoftwareUpdateMenuProvider()
        let controller = MenuBarController(
            defaultBrowserService: MockDefaultBrowserService(status: .isDefault),
            softwareUpdateMenuProvider: provider
        )

        let menu = controller.makeMenu()
        let updateItem = try #require(menu.items.first { $0.title == "Check for Updates…" })
        let updateIndex = try #require(menu.items.firstIndex(of: updateItem))
        let quitIndex = try #require(menu.items.firstIndex { $0.title == "Quit Portal" })

        #expect(provider.makeMenuItemCallCount == 1)
        #expect(updateItem.target === provider.target)
        #expect(updateItem.action == provider.action)
        #expect(updateIndex < quitIndex)
    }

    @Test("Sparkle provider is disabled when bundle has no update configuration")
    func sparkleProviderIsDisabledWithoutUpdateConfiguration() {
        #expect(SparkleSoftwareUpdateMenuProvider
            .makeConfigured(bundle: Bundle(for: StubSoftwareUpdateTarget.self)) == nil)
    }
}

private final class StubSoftwareUpdateMenuProvider: SoftwareUpdateMenuProviding {
    let target = StubSoftwareUpdateTarget()
    let action = #selector(StubSoftwareUpdateTarget.checkForUpdates(_:))
    private(set) var makeMenuItemCallCount = 0

    func makeSoftwareUpdateMenuItem() -> NSMenuItem? {
        self.makeMenuItemCallCount += 1
        let item = NSMenuItem(title: "Check for Updates…", action: self.action, keyEquivalent: "")
        item.target = self.target
        return item
    }
}

private final class StubSoftwareUpdateTarget: NSObject {
    @objc func checkForUpdates(_: Any?) {}
}
