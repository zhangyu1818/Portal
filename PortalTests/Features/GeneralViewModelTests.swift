import Foundation
@testable import Portal
import Testing

@Suite("GeneralViewModel default browser")
@MainActor
struct GeneralViewModelTests {
    @Test("default browser status reflects service")
    func defaultBrowserStatusReflectsService() async {
        let service = MockDefaultBrowserService(status: .isDefault)
        let viewModel = GeneralViewModel(defaultBrowserService: service)

        await viewModel.loadDefaultBrowserStatus()

        #expect(viewModel.isDefaultBrowser == true)
    }

    @Test("setAsDefault delegates to service")
    func setAsDefaultDelegatesToService() async {
        let service = MockDefaultBrowserService(
            status: .isDefault,
            makeDefaultResult: .success(())
        )
        let viewModel = GeneralViewModel(defaultBrowserService: service)

        await viewModel.setAsDefaultBrowser()

        let callCount = await service.makeDefaultCallCount
        #expect(callCount == 1)
    }
}
