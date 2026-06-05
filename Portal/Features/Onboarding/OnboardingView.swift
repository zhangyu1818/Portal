import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @State private var browsersViewModel: BrowsersViewModel
    var onDismiss: () -> Void

    init(viewModel: OnboardingViewModel, browsersViewModel: BrowsersViewModel, onDismiss: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel)
        _browsersViewModel = State(wrappedValue: browsersViewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        GlassEffectContainer {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    self.heroSection
                    self.featureCard
                    self.statusCard
                    if let error = viewModel.lastError {
                        InlineWarning(self.message(for: error))
                    }
                    self.actions
                }
                .padding(Spacing.xl)
            }
        }
        .task {
            if OnboardingPreferences.isDismissed {
                self.onDismiss()
                return
            }
            self.viewModel.startObserving()
            await self.viewModel.loadStatus()
            await self.browsersViewModel.load()
            await self.browsersViewModel.startObserving()
            self.viewModel.updateBrowsers(self.browsersViewModel.browsers)
        }
        .onChange(of: self.browsersViewModel.browsers) { _, newValue in
            self.viewModel.updateBrowsers(newValue)
        }
        .onChange(of: self.viewModel.status) { _, newValue in
            if newValue == .isDefault {
                OnboardingPreferences.markDismissed()
                self.onDismiss()
            }
        }
        .onDisappear {
            self.viewModel.stopObserving()
            self.browsersViewModel.stopObserving()
        }
    }

    private var heroSection: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)
            Text("Welcome to Portal", comment: "Onboarding hero title")
                .font(.titleHero)
            Text(
                "Smart routing for your http and https links",
                comment: "Onboarding hero subtitle"
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    private var featureCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                self.featureRow(
                    icon: "link",
                    title: LocalizedStringResource("Route by domain", comment: "Onboarding feature title — domain"),
                    body: LocalizedStringResource(
                        "Send work links to one browser, personal links to another.",
                        comment: "Onboarding feature subtitle — domain"
                    )
                )
                Divider()
                self.featureRow(
                    icon: "app.badge",
                    title: LocalizedStringResource(
                        "Route by source app",
                        comment: "Onboarding feature title — source app"
                    ),
                    body: LocalizedStringResource(
                        "Slack to Chrome. Notion to Safari. Automatically.",
                        comment: "Onboarding feature subtitle — source app"
                    )
                )
                Divider()
                self.featureRow(
                    icon: "arrow.triangle.branch",
                    title: LocalizedStringResource(
                        "Stays out of the way",
                        comment: "Onboarding feature title — invisible"
                    ),
                    body: LocalizedStringResource(
                        "Portal isn't a browser — it picks the right one and gets out.",
                        comment: "Onboarding feature subtitle — invisible"
                    )
                )
            }
        }
    }

    private func featureRow(icon: String, title: LocalizedStringResource, body: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusCard: some View {
        GlassCard {
            HStack {
                Text("Default Browser", comment: "Onboarding status row label")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(self.statusValue)
                    .font(.callout)
            }
        }
    }

    private var statusValue: String {
        switch self.viewModel.status {
        case .isDefault:
            String(localized: "Portal", comment: "Onboarding status value when Portal is default")
        case .otherBrowser:
            self.viewModel.defaultBrowserDisplayName
                ?? String(
                    localized: "Unknown",
                    comment: "Onboarding status value when default browser cannot be resolved"
                )
        case .unknown:
            String(localized: "Checking…", comment: "Onboarding status value while loading")
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.s) {
            Button {
                Task {
                    await self.viewModel.setAsDefault()
                    if self.viewModel.status == .isDefault {
                        OnboardingPreferences.markDismissed()
                        self.onDismiss()
                    }
                }
            } label: {
                Text("Set as Default Browser", comment: "Onboarding primary CTA")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(self.viewModel.status == .isDefault)

            Button {
                OnboardingPreferences.markDismissed()
                self.onDismiss()
            } label: {
                Text("Skip for Now", comment: "Onboarding secondary action")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }

    private func message(for error: DefaultBrowserError) -> LocalizedStringResource {
        switch error {
        case .applicationNotFound:
            LocalizedStringResource(
                "Portal isn't registered to handle web links yet. Try restarting the app.",
                comment: "Onboarding error — application not found"
            )
        case .userDeclined:
            LocalizedStringResource(
                "macOS didn't accept the change. Try again, or change it from System Settings.",
                comment: "Onboarding error — user declined"
            )
        case .notRegistered:
            LocalizedStringResource(
                "Portal couldn't find its bundle identifier.",
                comment: "Onboarding error — not registered"
            )
        case let .launchServicesFailed(status):
            LocalizedStringResource(
                "Setting Portal as default failed (status \(status)).",
                comment: "Onboarding error — LaunchServices failure"
            )
        }
    }
}
