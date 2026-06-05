import SwiftUI

struct SettingsRootView: View {
    private static let paneWidth: CGFloat = 520

    @State private var viewModel = SettingsViewModel()
    @State private var rulesViewModel: RulesViewModel
    @State private var browsersViewModel: BrowsersViewModel
    @State private var generalViewModel: GeneralViewModel

    init(
        ruleStore: any RuleStore,
        browserRegistry: any BrowserRegistry,
        defaultBrowserService: any DefaultBrowserService,
        fallbackPreferenceStore: any FallbackBrowserPreferenceStore
    ) {
        _rulesViewModel = State(initialValue: RulesViewModel(store: ruleStore))
        _browsersViewModel = State(initialValue: BrowsersViewModel(
            registry: browserRegistry,
            fallbackPreferenceStore: fallbackPreferenceStore
        ))
        _generalViewModel = State(initialValue: GeneralViewModel(defaultBrowserService: defaultBrowserService))
    }

    var body: some View {
        TabView(selection: self.$viewModel.selectedPane) {
            BrowsersView(viewModel: self.browsersViewModel, rulesViewModel: self.rulesViewModel)
                .frame(width: Self.paneWidth)
                .tabItem { self.label(for: .browsers) }
                .tag(SettingsPane.browsers)

            GeneralView(viewModel: self.generalViewModel)
                .frame(width: Self.paneWidth)
                .tabItem { self.label(for: .general) }
                .tag(SettingsPane.general)
        }
    }

    private func label(for pane: SettingsPane) -> some View {
        Label(String(localized: pane.title), systemImage: pane.systemImage)
    }
}
