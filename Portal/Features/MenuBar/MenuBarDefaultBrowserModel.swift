import Foundation
import Observation

@MainActor
@Observable
final class MenuBarDefaultBrowserModel {
    private let defaultBrowserService: any DefaultBrowserService
    private(set) var shouldShowSetDefaultBrowserItem = false
    private(set) var isSettingDefaultBrowser = false

    init(defaultBrowserService: any DefaultBrowserService) {
        self.defaultBrowserService = defaultBrowserService
    }

    func loadDefaultBrowserStatus() async {
        let status = await self.defaultBrowserService.currentStatus()
        self.apply(status)
    }

    func observeDefaultBrowserStatus() async {
        await self.loadDefaultBrowserStatus()

        let stream = self.defaultBrowserService.observe()
        for await status in stream {
            guard !Task.isCancelled else { break }
            self.apply(status)
        }
    }

    func setAsDefaultBrowser() async {
        guard !self.isSettingDefaultBrowser else { return }

        self.isSettingDefaultBrowser = true
        let result = await self.defaultBrowserService.makePortalDefault()
        self.isSettingDefaultBrowser = false

        switch result {
        case .success:
            self.apply(.isDefault)
        case .failure:
            await self.loadDefaultBrowserStatus()
        }
    }

    private func apply(_ status: DefaultBrowserStatus) {
        self.shouldShowSetDefaultBrowserItem = status != .isDefault
    }
}
