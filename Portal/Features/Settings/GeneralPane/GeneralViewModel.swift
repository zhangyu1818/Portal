import Foundation
import Observation

@MainActor
@Observable
final class GeneralViewModel {
    private(set) var isDefaultBrowser: Bool = false
    private let defaultBrowserService: any DefaultBrowserService
    private var observeTask: Task<Void, Never>?

    init(defaultBrowserService: any DefaultBrowserService) {
        self.defaultBrowserService = defaultBrowserService
    }

    func loadDefaultBrowserStatus() async {
        let status = await self.defaultBrowserService.currentStatus()
        self.isDefaultBrowser = status == .isDefault
    }

    func startObservingDefaultBrowserStatus() {
        self.observeTask?.cancel()
        self.observeTask = Task { [weak self] in
            guard let self else { return }
            let stream = self.defaultBrowserService.observe()
            for await status in stream {
                guard !Task.isCancelled else { break }
                self.isDefaultBrowser = status == .isDefault
            }
        }
    }

    func setAsDefaultBrowser() async {
        _ = await self.defaultBrowserService.makePortalDefault()
        await self.loadDefaultBrowserStatus()
    }
}
