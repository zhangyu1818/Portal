import AppKit
import Carbon
import Foundation

@MainActor
protocol MenuBarControlling: AnyObject {
    func start()
}

@MainActor
protocol SettingsOpening: AnyObject {
    func openSettings()
}

extension MenuBarController: MenuBarControlling {}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController: any MenuBarControlling
    private let settingsOpener: any SettingsOpening
    private let isRunningXCTest: @MainActor () -> Bool
    private let currentAppleEventSenderPID: @MainActor () -> pid_t?
    private var urlRouter: URLRouter?
    private var sourceAppDetector: (any SourceAppDetector)?
    private(set) var currentRouteTask: Task<Void, Never>?

    override convenience init() {
        self.init(urlRouter: nil)
    }

    init(
        urlRouter: URLRouter?,
        sourceAppDetector: (any SourceAppDetector)? = nil,
        menuBarController: any MenuBarControlling = MenuBarController(),
        settingsOpener: any SettingsOpening = SettingsOpenRequestCenter.shared,
        currentAppleEventSenderPID: @escaping @MainActor () -> pid_t? = AppDelegate.currentAppleEventSenderPID,
        isRunningXCTest: @escaping @MainActor () -> Bool = AppRuntime.isRunningXCTest
    ) {
        self.urlRouter = urlRouter
        self.sourceAppDetector = sourceAppDetector
        self.menuBarController = menuBarController
        self.settingsOpener = settingsOpener
        self.currentAppleEventSenderPID = currentAppleEventSenderPID
        self.isRunningXCTest = isRunningXCTest
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        if self.urlRouter == nil || self.sourceAppDetector == nil {
            let dependencies = AppDependencies.shared
            if self.urlRouter == nil {
                self.urlRouter = dependencies.urlRouter
            }
            if self.sourceAppDetector == nil {
                self.sourceAppDetector = dependencies.sourceAppDetector
            }
        }

        if !self.isRunningXCTest() {
            self.menuBarController.start()
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        self.settingsOpener.openSettings()
        return false
    }

    func application(_: NSApplication, open urls: [URL]) {
        let senderPID = self.currentAppleEventSenderPID()
        PortalDebugLog.route(
            "appDelegate.openURLs",
            [
                ("urls", urls.map(\.absoluteString).joined(separator: ",")),
                ("currentAppleEventSenderPID", senderPID.map(String.init) ?? "nil"),
            ]
        )
        let router = self.urlRouter ?? AppDependencies.shared.urlRouter
        let sourceAppDetector = self.sourceAppDetector ?? AppDependencies.shared.sourceAppDetector
        let task = Task { @MainActor in
            if let senderPID {
                let sourceApp = await sourceAppDetector.source(forSenderPID: senderPID)
                await router.route(urls, sourceApp: sourceApp)
            } else {
                await router.route(urls)
            }
        }
        self.currentRouteTask = task
    }

    private static func currentAppleEventSenderPID() -> pid_t? {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else {
            return nil
        }
        guard let descriptor = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr)) else {
            return nil
        }
        let pid = pid_t(descriptor.int32Value)
        return pid > 0 ? pid : nil
    }
}

enum AppRuntime {
    static func isRunningXCTest() -> Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
