import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    private let service: any DefaultBrowserService
    private(set) var status: DefaultBrowserStatus = .unknown
    private(set) var lastError: DefaultBrowserError?
    private var observeTask: Task<Void, Never>?

    init(service: any DefaultBrowserService) {
        self.service = service
    }

    private(set) var browsers: [Browser] = []

    func updateBrowsers(_ browsers: [Browser]) {
        self.browsers = browsers
    }

    var defaultBrowserDisplayName: String? {
        guard case let .otherBrowser(bundleIdentifier?) = self.status else { return nil }
        return self.browsers.first(where: { $0.bundleIdentifier == bundleIdentifier })?.displayName
            ?? bundleIdentifier
    }

    func loadStatus() async {
        self.status = await self.service.currentStatus()
    }

    func setAsDefault() async {
        self.lastError = nil
        let result = await self.service.makePortalDefault()
        switch result {
        case .success:
            self.lastError = nil
            await self.loadStatus()
        case let .failure(error):
            self.lastError = error
        }
    }

    func startObserving() {
        self.observeTask?.cancel()
        self.observeTask = Task { [weak self] in
            guard let self else { return }
            let stream = self.service.observe()
            for await status in stream {
                guard !Task.isCancelled else { break }
                self.status = status
            }
        }
    }

    func stopObserving() {
        self.observeTask?.cancel()
        self.observeTask = nil
    }
}
