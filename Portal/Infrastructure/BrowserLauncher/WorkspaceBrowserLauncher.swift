import AppKit

public struct WorkspaceBrowserLauncher: BrowserLauncher {
    public init() {}

    public func launch(_ url: URL, in browser: Browser) async throws {
        let appURL = browser.bundleURL
        guard FileManager.default.fileExists(atPath: appURL.path()) else {
            throw BrowserLauncherError.browserNotFound(bundleIdentifier: browser.bundleIdentifier)
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        do {
            _ = try await NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config)
        } catch {
            throw BrowserLauncherError.launchFailed(underlying: error)
        }
    }
}
