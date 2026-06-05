import AppKit
import SwiftUI

@main
struct PortalApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.openSettings) private var openSettings

    private let dependencies = AppDependencies.shared

    var body: some Scene {
        SettingsOpenAccessScene(
            openSettings: {
                self.openSettings()
                NSApp.activate(ignoringOtherApps: true)
            },
            content: {
                AppLifecycleScene()

                Settings {
                    SettingsRootView(
                        ruleStore: self.dependencies.ruleStore,
                        browserRegistry: self.dependencies.browserRegistry,
                        defaultBrowserService: self.dependencies.defaultBrowserService,
                        fallbackPreferenceStore: self.dependencies.fallbackPreferenceStore
                    )
                }

                OnboardingWindow(
                    defaultBrowserService: self.dependencies.defaultBrowserService,
                    browserRegistry: self.dependencies.browserRegistry
                )
            }
        )
    }
}
