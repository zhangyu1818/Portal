import Foundation
@testable import Portal
import Testing

@MainActor
@Suite("OnboardingViewModel.defaultBrowserDisplayName")
struct OnboardingViewModelDisplayNameTests {
    @Test("Returns nil when status is unknown")
    func unknownStatusReturnsNil() {
        let service = StubDefaultBrowserService(initial: .unknown)
        let viewModel = OnboardingViewModel(service: service)
        viewModel.updateBrowsers([])
        #expect(viewModel.defaultBrowserDisplayName == nil)
    }

    @Test("Returns nil when Portal is the default")
    func isDefaultReturnsNil() async {
        let service = StubDefaultBrowserService(initial: .isDefault)
        let viewModel = OnboardingViewModel(service: service)
        await viewModel.loadStatus()
        viewModel.updateBrowsers([])
        #expect(viewModel.defaultBrowserDisplayName == nil)
    }

    @Test("Returns displayName when bundle id is in browsers snapshot")
    func returnsDisplayNameWhenKnown() async {
        let service = StubDefaultBrowserService(initial: .otherBrowser(bundleIdentifier: "com.apple.Safari"))
        let viewModel = OnboardingViewModel(service: service)
        await viewModel.loadStatus()
        viewModel.updateBrowsers([
            Browser(
                bundleIdentifier: "com.apple.Safari",
                displayName: "Safari",
                bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")
            ),
        ])
        #expect(viewModel.defaultBrowserDisplayName == "Safari")
    }

    @Test("Falls back to bundle id when not in browsers snapshot")
    func fallsBackToBundleID() async {
        let service = StubDefaultBrowserService(initial: .otherBrowser(bundleIdentifier: "com.unknown.browser"))
        let viewModel = OnboardingViewModel(service: service)
        await viewModel.loadStatus()
        viewModel.updateBrowsers([])
        #expect(viewModel.defaultBrowserDisplayName == "com.unknown.browser")
    }
}

private actor StubDefaultBrowserService: DefaultBrowserService {
    private let initial: DefaultBrowserStatus

    init(initial: DefaultBrowserStatus) {
        self.initial = initial
    }

    func currentStatus() async -> DefaultBrowserStatus {
        self.initial
    }

    func makePortalDefault() async -> Result<Void, DefaultBrowserError> {
        .success(())
    }

    nonisolated func observe() -> AsyncStream<DefaultBrowserStatus> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
