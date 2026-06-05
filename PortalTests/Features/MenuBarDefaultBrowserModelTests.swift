@testable import Portal
import Testing

@Suite("MenuBarDefaultBrowserModel")
@MainActor
struct MenuBarDefaultBrowserModelTests {
    @Test("set default menu item is hidden when Portal is default")
    func setDefaultItemIsHiddenWhenPortalIsDefault() async {
        let service = MutableDefaultBrowserService(status: .isDefault)
        let model = MenuBarDefaultBrowserModel(defaultBrowserService: service)

        await model.loadDefaultBrowserStatus()

        #expect(model.shouldShowSetDefaultBrowserItem == false)
    }

    @Test("set default menu item is shown when another browser is default")
    func setDefaultItemIsShownWhenAnotherBrowserIsDefault() async {
        let service = MutableDefaultBrowserService(status: .otherBrowser(bundleIdentifier: "com.apple.Safari"))
        let model = MenuBarDefaultBrowserModel(defaultBrowserService: service)

        await model.loadDefaultBrowserStatus()

        #expect(model.shouldShowSetDefaultBrowserItem == true)
    }

    @Test("setting default browser delegates to service and hides item on success")
    func settingDefaultBrowserDelegatesToServiceAndHidesItemOnSuccess() async {
        let service = MutableDefaultBrowserService(status: .otherBrowser(bundleIdentifier: "com.apple.Safari"))
        let model = MenuBarDefaultBrowserModel(defaultBrowserService: service)

        await model.loadDefaultBrowserStatus()
        await model.setAsDefaultBrowser()

        let callCount = await service.makeDefaultCallCount
        #expect(callCount == 1)
        #expect(model.shouldShowSetDefaultBrowserItem == false)
    }
}

private actor MutableDefaultBrowserService: DefaultBrowserService {
    private var status: DefaultBrowserStatus
    private(set) var makeDefaultCallCount = 0

    init(status: DefaultBrowserStatus) {
        self.status = status
    }

    func currentStatus() async -> DefaultBrowserStatus {
        self.status
    }

    func makePortalDefault() async -> Result<Void, DefaultBrowserError> {
        self.makeDefaultCallCount += 1
        self.status = .isDefault
        return .success(())
    }

    nonisolated func observe() -> AsyncStream<DefaultBrowserStatus> {
        AsyncStream { continuation in
            Task {
                let status = await self.currentStatus()
                continuation.yield(status)
                continuation.finish()
            }
        }
    }
}
