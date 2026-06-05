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
}
