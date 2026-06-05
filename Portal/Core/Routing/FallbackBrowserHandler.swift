import Foundation

struct FallbackBrowserHandler {
    private let preferenceStore: any FallbackBrowserPreferenceStore
    private let browserRegistry: any BrowserRegistry
    private let loopGuard: any LoopGuardProtocol
    private let browserLauncher: any BrowserLauncher

    init(
        preferenceStore: any FallbackBrowserPreferenceStore,
        browserRegistry: any BrowserRegistry,
        loopGuard: any LoopGuardProtocol,
        browserLauncher: any BrowserLauncher
    ) {
        self.preferenceStore = preferenceStore
        self.browserRegistry = browserRegistry
        self.loopGuard = loopGuard
        self.browserLauncher = browserLauncher
    }

    func openIfAvailable(url: URL, loadedRules: [Rule]?) async -> Bool {
        guard let browser = await self.fallbackBrowser(loadedRules: loadedRules) else { return false }

        guard await self.loopGuard.recordAndCheck(url: url, browserBundleID: browser.bundleIdentifier) else {
            PortalDebugLog.route("router.fallback.blockedByLoopGuard", [
                ("url", url.absoluteString),
                ("browser", browser.bundleIdentifier),
            ])
            return true
        }

        do {
            try await self.browserLauncher.launch(url, in: browser)
            self.logLaunch(status: "success", url: url, browser: browser.bundleIdentifier)
        } catch {
            self.logLaunch(status: "failed", url: url, browser: browser.bundleIdentifier, error: error)
            #if DEBUG
                print("[URLRouter] Launch failed for host \(url.host() ?? "<no host>"): \(error)")
            #endif
        }
        return true
    }

    private func fallbackBrowser(loadedRules: [Rule]?) async -> Browser? {
        guard loadedRules != nil else {
            PortalDebugLog.route("router.fallback.skip", [("reason", "rulesLoadFailed")])
            return nil
        }

        guard let bundleID = await preferenceStore.fallbackBrowserBundleID() else {
            PortalDebugLog.route("router.fallback.skip", [("reason", "askEveryTime")])
            return nil
        }

        guard bundleID != Bundle.main.bundleIdentifier else {
            PortalDebugLog.route("router.fallback.skip", [("reason", "selfBrowser")])
            return nil
        }

        let browsers = await browserRegistry.current()
        guard let browser = browsers.first(where: { $0.bundleIdentifier == bundleID }) else {
            PortalDebugLog.route("router.fallback.skip", [
                ("reason", "browserNotFound"),
                ("bundleID", bundleID),
                ("availableBrowsers", browsers.map(\.bundleIdentifier).joined(separator: ",")),
            ])
            return nil
        }

        PortalDebugLog.route("router.fallback.match", [("browser", browser.bundleIdentifier)])
        return browser
    }

    private func logLaunch(
        status: String,
        url: URL,
        browser: String,
        error: (any Error)? = nil
    ) {
        var fields = [
            ("status", status),
            ("url", url.absoluteString),
            ("browser", browser),
        ]
        if let error {
            fields.append(("error", String(describing: error)))
        }
        PortalDebugLog.route("router.launch", fields)
    }
}
