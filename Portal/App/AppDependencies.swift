import Foundation
import Observation

@MainActor
@Observable
final class AppDependencies {
    static let shared = AppDependencies()

    let ruleStore: any RuleStore
    let browserRegistry: any BrowserRegistry
    let defaultBrowserService: any DefaultBrowserService
    let sourceAppDetector: any SourceAppDetector
    let browserLauncher: any BrowserLauncher
    let loopGuard: LoopGuard
    let ruleEngine: any RuleEngine
    let pickerCoordinator: any PickerCoordinator
    let fallbackPreferenceStore: any FallbackBrowserPreferenceStore
    let urlRouter: URLRouter

    init() {
        let store: any RuleStore = (try? JSONFileRuleStore())
            ?? JSONFileRuleStore(directory: FileManager.default.temporaryDirectory)
        let registry = LaunchServicesBrowserRegistry()
        let detector = AppleEventSourceAppDetector()
        let launcher = WorkspaceBrowserLauncher()
        let loopGuard = LoopGuard()
        let engine = DefaultRuleEngine()
        let picker = NSPanelPickerCoordinator(browserRegistry: registry)
        let fallbackPreferenceStore = UserDefaultsFallbackStore()

        self.ruleStore = store
        self.browserRegistry = registry
        self.defaultBrowserService = makeDefaultBrowserService()
        self.sourceAppDetector = detector
        self.browserLauncher = launcher
        self.loopGuard = loopGuard
        self.ruleEngine = engine
        self.pickerCoordinator = picker
        self.fallbackPreferenceStore = fallbackPreferenceStore
        self.urlRouter = URLRouter(
            ruleStore: store,
            ruleEngine: engine,
            sourceAppDetector: detector,
            browserLauncher: launcher,
            browserRegistry: registry,
            loopGuard: loopGuard,
            pickerCoordinator: picker,
            fallbackPreferenceStore: fallbackPreferenceStore
        )
        detector.start()
    }
}
