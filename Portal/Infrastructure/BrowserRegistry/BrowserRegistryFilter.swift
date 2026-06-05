import Foundation

enum BrowserRegistryFilter {
    static func filterBrowsers(_ browsers: [Browser], excludingSelf selfBundleID: String) -> [Browser] {
        var seen: Set<String> = []
        return browsers.compactMap { browser in
            guard browser.bundleIdentifier != selfBundleID else { return nil }
            guard !Self.isNestedAppBundle(browser.bundleURL) else { return nil }
            guard seen.insert(browser.bundleIdentifier).inserted else { return nil }
            return browser
        }
    }

    static func sort(_ browsers: [Browser]) -> [Browser] {
        browsers.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    /// True when the given `.app` URL lives inside another `.app` — e.g. a helper
    /// or web-view bundle such as `com.openai.atlas.web` packaged inside the
    /// main ChatGPT Atlas app. LaunchServices reports these as URL handlers, but
    /// they are not standalone browsers.
    static func isNestedAppBundle(_ url: URL) -> Bool {
        let parentPath = url.deletingLastPathComponent().path
        return parentPath.contains(".app/") || parentPath.hasSuffix(".app")
    }
}
