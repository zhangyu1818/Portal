import AppKit
import Foundation
@testable import Portal
import Testing

@Suite("AppDelegate routing", .tags(.integration))
@MainActor
struct AppDelegateRoutingTests {
    @Test("applicationDidFinishLaunching starts menu bar controller outside XCTest")
    func launchStartsMenuBarControllerOutsideXCTest() {
        let components = makeRouter()
        let menuBarController = SpyMenuBarController()
        let delegate = AppDelegate(
            urlRouter: components.router,
            menuBarController: menuBarController,
            isRunningXCTest: { false }
        )

        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(menuBarController.startCallCount == 1)
    }

    @Test("applicationDidFinishLaunching skips menu bar controller under XCTest")
    func launchSkipsMenuBarControllerUnderXCTest() {
        let components = makeRouter()
        let menuBarController = SpyMenuBarController()
        let delegate = AppDelegate(
            urlRouter: components.router,
            menuBarController: menuBarController,
            isRunningXCTest: { true }
        )

        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(menuBarController.startCallCount == 0)
    }

    @Test("application(_:open:) routes URLs to URLRouter")
    func routesURLsToRouter() async throws {
        let components = makeRouter(
            ruleMatch: .noMatch,
            pickerChoice: nil
        )
        let delegate = AppDelegate(urlRouter: components.router)
        let url = try #require(URL(string: "https://example.com"))

        delegate.application(NSApplication.shared, open: [url])
        await delegate.currentRouteTask?.value

        let presentations = await components.picker.presentedURLs
        #expect(presentations.count == 1)
        #expect(presentations[0] == url)
    }

    @Test("application(_:open:) uses the current Apple Event sender PID as the source app")
    func openUsesCurrentAppleEventSenderPIDAsSourceApp() async throws {
        let slack = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let dia = Browser(
            bundleIdentifier: "company.thebrowser.dia",
            displayName: "Dia",
            bundleURL: URL(fileURLWithPath: "/Applications/Dia.app")
        )
        let ruleStore = MockRuleStore(rules: [
            .sourceApp(SourceAppRule(sourceBundleID: slack.bundleIdentifier, browserBundleID: dia.bundleIdentifier)),
        ])
        let detector = MockSourceAppDetector(source: nil, pidSources: [72058: slack])
        let launcher = MockBrowserLauncher()
        let picker = MockPickerCoordinator(choice: nil)
        let router = URLRouter(
            ruleStore: ruleStore,
            ruleEngine: DefaultRuleEngine(),
            sourceAppDetector: detector,
            browserLauncher: launcher,
            browserRegistry: MockBrowserRegistry(browsers: [dia]),
            loopGuard: MockLoopGuard(allow: true),
            pickerCoordinator: picker
        )
        let delegate = AppDelegate(
            urlRouter: router,
            sourceAppDetector: detector,
            currentAppleEventSenderPID: { 72058 }
        )
        let url = try #require(URL(string: "https://example.com"))

        delegate.application(NSApplication.shared, open: [url])
        await delegate.currentRouteTask?.value

        let calls = await launcher.recordedCalls
        let presentations = await picker.presentedURLs
        #expect(calls.count == 1)
        #expect(calls[0].browser == dia)
        #expect(presentations.isEmpty)
    }

    @Test("application(_:open:) with empty URLs does nothing")
    func emptyURLsDoesNothing() async {
        let components = makeRouter()
        let delegate = AppDelegate(urlRouter: components.router)

        delegate.application(NSApplication.shared, open: [])
        await delegate.currentRouteTask?.value

        let calls = await components.launcher.recordedCalls
        let presentations = await components.picker.presentedURLs
        #expect(calls.isEmpty)
        #expect(presentations.isEmpty)
    }
}

private final class SpyMenuBarController: MenuBarControlling {
    private(set) var startCallCount = 0

    func start() {
        self.startCallCount += 1
    }
}
