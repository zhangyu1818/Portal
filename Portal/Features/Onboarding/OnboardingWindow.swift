import SwiftUI

struct OnboardingWindow: Scene {
    let defaultBrowserService: any DefaultBrowserService
    let browserRegistry: any BrowserRegistry
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Scene {
        Window(
            Text("Welcome to Portal", comment: "Onboarding window title"),
            id: "onboarding"
        ) {
            OnboardingView(
                viewModel: OnboardingViewModel(service: self.defaultBrowserService),
                browsersViewModel: BrowsersViewModel(registry: self.browserRegistry),
                onDismiss: { self.dismissWindow(id: "onboarding") }
            )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 540)
        .defaultLaunchBehavior(.presented)
    }
}
