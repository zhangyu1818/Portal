import Foundation
@testable import Portal
import Testing

@Suite("BrowserRegistryFilter")
struct BrowserRegistryFilterTests {
    private func makeBrowser(id: String, name: String) -> Browser {
        Browser(bundleIdentifier: id, displayName: name, bundleURL: URL(filePath: "/\(id)"))
    }

    @Test("excludes self bundle ID from list")
    func excludesSelf() {
        let browsers = [
            makeBrowser(id: "a", name: "A"),
            makeBrowser(id: "dev.zhangyu.portal", name: "Portal"),
            makeBrowser(id: "b", name: "B"),
        ]
        let result = BrowserRegistryFilter.filterBrowsers(browsers, excludingSelf: "dev.zhangyu.portal")
        #expect(result.map(\.bundleIdentifier) == ["a", "b"])
    }

    @Test("returns all when self is not present")
    func noSelfPresent() {
        let browsers = [
            makeBrowser(id: "a", name: "A"),
            makeBrowser(id: "b", name: "B"),
        ]
        let result = BrowserRegistryFilter.filterBrowsers(browsers, excludingSelf: "dev.zhangyu.portal")
        #expect(result.map(\.bundleIdentifier) == ["a", "b"])
    }

    @Test("deduplicates preserving first occurrence order")
    func deduplicates() {
        let browsers = [
            makeBrowser(id: "a", name: "A"),
            makeBrowser(id: "b", name: "B"),
            makeBrowser(id: "a", name: "A2"),
        ]
        let result = BrowserRegistryFilter.filterBrowsers(browsers, excludingSelf: "dev.zhangyu.portal")
        #expect(result.map(\.bundleIdentifier) == ["a", "b"])
    }

    @Test("sorts browsers case-insensitively by displayName")
    func sortByDisplayName() {
        let safari = Browser(bundleIdentifier: "c1", displayName: "Safari", bundleURL: URL(filePath: "/a"))
        let arc = Browser(bundleIdentifier: "c2", displayName: "Arc", bundleURL: URL(filePath: "/b"))
        let chrome = Browser(bundleIdentifier: "c3", displayName: "chrome", bundleURL: URL(filePath: "/c"))
        let sorted = BrowserRegistryFilter.sort([safari, arc, chrome])
        #expect(sorted.map(\.displayName) == ["Arc", "chrome", "Safari"])
    }

    @Test("empty input returns empty output")
    func emptyInputReturnsEmpty() {
        #expect(BrowserRegistryFilter.filterBrowsers([], excludingSelf: "any.id").isEmpty)
        #expect(BrowserRegistryFilter.sort([]).isEmpty)
    }

    @Test("filters out helper bundles nested inside another .app")
    func filtersNestedHelperBundles() {
        let mainApp = Browser(
            bundleIdentifier: "com.openai.atlas",
            displayName: "ChatGPT Atlas",
            bundleURL: URL(filePath: "/Applications/ChatGPT Atlas.app/")
        )
        let helperBundle = Browser(
            bundleIdentifier: "com.openai.atlas.web",
            displayName: "ChatGPT Atlas",
            bundleURL: URL(filePath: "/Applications/ChatGPT Atlas.app/Contents/Helpers/Web.app/")
        )
        let result = BrowserRegistryFilter.filterBrowsers([mainApp, helperBundle], excludingSelf: "any.id")
        #expect(result.map(\.bundleIdentifier) == ["com.openai.atlas"])
    }

    @Test("isNestedAppBundle distinguishes top-level apps from nested bundles")
    func nestedDetection() {
        #expect(!BrowserRegistryFilter.isNestedAppBundle(URL(filePath: "/Applications/Safari.app/")))
        #expect(!BrowserRegistryFilter.isNestedAppBundle(URL(filePath: "/Users/me/Apps/Foo.app")))
        #expect(BrowserRegistryFilter.isNestedAppBundle(
            URL(filePath: "/Applications/Outer.app/Contents/Helpers/Inner.app/")
        ))
        #expect(BrowserRegistryFilter.isNestedAppBundle(
            URL(filePath: "/Applications/Outer.app/Contents/Helpers/Inner.app")
        ))
    }
}
