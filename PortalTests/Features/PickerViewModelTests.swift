import Foundation
@testable import Portal
import Testing

@Suite("PickerViewModel")
@MainActor
struct PickerViewModelTests {
    private func makeBrowser(_ id: String) -> Browser {
        Browser(
            bundleIdentifier: id,
            displayName: id,
            bundleURL: URL(filePath: "/Applications/\(id).app")
        )
    }

    @Test("initialRememberIsFalse")
    func initialRememberIsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        let viewModel = PickerViewModel(url: url, sourceApp: nil, browsers: [])
        #expect(viewModel.remember == false)
    }

    @Test("chooseReturnsSelectedBrowserWithRememberFalse")
    func chooseReturnsSelectedBrowserWithRememberFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        let safari = self.makeBrowser("com.apple.safari")
        let viewModel = PickerViewModel(url: url, sourceApp: nil, browsers: [safari])
        viewModel.remember = false
        let choice = viewModel.choose(safari)
        #expect(choice.browser == safari)
        #expect(choice.remember == false)
    }

    @Test("chooseReturnsSelectedBrowserWithRememberTrue")
    func chooseReturnsSelectedBrowserWithRememberTrue() throws {
        let url = try #require(URL(string: "https://example.com"))
        let chrome = self.makeBrowser("com.google.Chrome")
        let viewModel = PickerViewModel(url: url, sourceApp: nil, browsers: [chrome])
        viewModel.remember = true
        let choice = viewModel.choose(chrome)
        #expect(choice.browser == chrome)
        #expect(choice.remember == true)
    }

    @Test("browsersListExposesProvidedList")
    func browsersListExposesProvidedList() throws {
        let url = try #require(URL(string: "https://example.com"))
        let safari = self.makeBrowser("com.apple.safari")
        let chrome = self.makeBrowser("com.google.Chrome")
        let firefox = self.makeBrowser("org.mozilla.firefox")
        let viewModel = PickerViewModel(url: url, sourceApp: nil, browsers: [safari, chrome, firefox])
        #expect(viewModel.browsers == [safari, chrome, firefox])
    }

    @Test("urlAndSourceAppExposed")
    func urlAndSourceAppExposed() throws {
        let url = try #require(URL(string: "https://example.com"))
        let sourceApp = SourceApp(bundleIdentifier: "com.slack", displayName: "Slack")
        let viewModel = PickerViewModel(url: url, sourceApp: sourceApp, browsers: [])
        #expect(viewModel.url == url)
        #expect(viewModel.sourceApp == sourceApp)
    }
}
