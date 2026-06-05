import Foundation
@testable import Portal
import Testing

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {
    @Test("initial status is unknown")
    func initialStatusIsUnknown() {
        let viewModel = OnboardingViewModel(service: MockDefaultBrowserService(status: .unknown))

        #expect(viewModel.status == .unknown)
    }

    @Test("loadStatus updates published status")
    func loadStatusUpdatesPublishedStatus() async {
        let service = MockDefaultBrowserService(status: .isDefault)
        let viewModel = OnboardingViewModel(service: service)

        await viewModel.loadStatus()

        #expect(viewModel.status == .isDefault)
    }

    @Test("setAsDefault updates status on success")
    func setAsDefaultUpdatesStatusOnSuccess() async {
        let service = MockDefaultBrowserService(
            status: .isDefault,
            makeDefaultResult: .success(())
        )
        let viewModel = OnboardingViewModel(service: service)

        await viewModel.setAsDefault()

        #expect(viewModel.lastError == nil)
        #expect(viewModel.status == .isDefault)
    }

    @Test("setAsDefault stores error on failure")
    func setAsDefaultStoresErrorOnFailure() async {
        let service = MockDefaultBrowserService(
            status: .unknown,
            makeDefaultResult: .failure(.notRegistered)
        )
        let viewModel = OnboardingViewModel(service: service)

        await viewModel.setAsDefault()

        #expect(viewModel.lastError == .notRegistered)
    }
}
