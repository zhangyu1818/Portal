import AppKit

public struct WorkspaceBrowserLauncher: BrowserLauncher {
    private let applicationURLForBundleIdentifier: @Sendable (String) -> URL?
    private let fileExists: @Sendable (String) -> Bool
    private let openURLs: @Sendable ([URL], URL, NSWorkspace.OpenConfiguration) async throws -> Void

    public init() {
        self.init(
            applicationURLForBundleIdentifier: { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) },
            fileExists: { FileManager.default.fileExists(atPath: $0) },
            openURLs: { urls, appURL, configuration in
                _ = try await NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: configuration)
            }
        )
    }

    init(
        applicationURLForBundleIdentifier: @escaping @Sendable (String) -> URL?,
        fileExists: @escaping @Sendable (String) -> Bool,
        openURLs: @escaping @Sendable ([URL], URL, NSWorkspace.OpenConfiguration) async throws -> Void
    ) {
        self.applicationURLForBundleIdentifier = applicationURLForBundleIdentifier
        self.fileExists = fileExists
        self.openURLs = openURLs
    }

    public func launch(_ url: URL, in browser: Browser) async throws {
        guard let appURL = self.applicationURL(for: browser) else {
            throw BrowserLauncherError.browserNotFound(bundleIdentifier: browser.bundleIdentifier)
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        do {
            try await self.openURLs([url], appURL, config)
        } catch {
            throw BrowserLauncherError.launchFailed(underlying: error)
        }
    }

    private func applicationURL(for browser: Browser) -> URL? {
        let resolvedURL = self.applicationURLForBundleIdentifier(browser.bundleIdentifier)
        let resolvedPath = resolvedURL?.path(percentEncoded: false)
        let cachedPath = browser.bundleURL.path(percentEncoded: false)
        let resolvedExists = resolvedPath.map { self.fileExists($0) } ?? false
        let cachedExists = self.fileExists(cachedPath)

        PortalDebugLog.route("browserLauncher.resolve", [
            ("bundleID", browser.bundleIdentifier),
            ("resolvedURL", resolvedPath ?? "nil"),
            ("resolvedExists", "\(resolvedExists)"),
            ("cachedURL", cachedPath),
            ("cachedExists", "\(cachedExists)"),
        ])

        if let resolvedURL, resolvedExists {
            return resolvedURL
        }

        if cachedExists {
            return browser.bundleURL
        }

        return nil
    }
}
