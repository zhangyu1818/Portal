import AppKit
import LaunchAtLogin
import SwiftUI

struct GeneralView: View {
    enum VersionPlacement {
        case footerNote
    }

    static let versionPlacement = VersionPlacement.footerNote
    static let includesMenuBarIconDescription = false

    @AppStorage(AppPresencePreferences.showsMenuBarIconKey) private var showsMenuBarIcon =
        AppPresencePreferences.defaultShowsMenuBarIcon

    @Bindable var viewModel: GeneralViewModel

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    LabeledContent {
                        self.defaultBrowserTrailing
                    } label: {
                        Text("Default browser", comment: "General pane row label — default browser status")
                    }
                }

                Section {
                    LaunchAtLogin.Toggle {
                        Text("Open at login", comment: "Toggle to launch Portal automatically at login")
                    }
                }

                Section {
                    Toggle(isOn: self.$showsMenuBarIcon) {
                        Text("Show menu bar icon", comment: "Toggle to show Portal in the macOS menu bar")
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Text("Version \(self.versionString)", comment: "Footer note showing app version")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
        .task {
            await self.viewModel.loadDefaultBrowserStatus()
            self.viewModel.startObservingDefaultBrowserStatus()
        }
    }

    @ViewBuilder
    private var defaultBrowserTrailing: some View {
        if self.viewModel.isDefaultBrowser {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Portal", comment: "App name shown as the current default browser")
                    .foregroundStyle(.secondary)
            }
        } else {
            Button {
                Task { await self.viewModel.setAsDefaultBrowser() }
            } label: {
                Text("Set as Default…", comment: "Button to make Portal the default browser")
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
