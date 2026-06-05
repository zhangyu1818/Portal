import SwiftUI

struct MenuBarMenuView: View {
    @State private var defaultBrowserModel: MenuBarDefaultBrowserModel
    private let quit: @MainActor () -> Void

    init(
        defaultBrowserService: any DefaultBrowserService = makeDefaultBrowserService(),
        quit: @escaping @MainActor () -> Void
    ) {
        self._defaultBrowserModel = State(
            initialValue: MenuBarDefaultBrowserModel(defaultBrowserService: defaultBrowserService)
        )
        self.quit = quit
    }

    var body: some View {
        Group {
            if self.defaultBrowserModel.shouldShowSetDefaultBrowserItem {
                Button {
                    Task {
                        await self.defaultBrowserModel.setAsDefaultBrowser()
                    }
                } label: {
                    Text("Set as Default Browser", comment: "Menu bar item that makes Portal the default browser")
                }
                .disabled(self.defaultBrowserModel.isSettingDefaultBrowser)

                Divider()
            }

            SettingsLink {
                Text("Open Settings…", comment: "Menu bar item that opens the Settings window")
            }

            Divider()

            Button {
                self.quit()
            } label: {
                Text("Quit Portal", comment: "Menu bar item that quits the application")
            }
            .keyboardShortcut("q")
        }
        .task {
            await self.defaultBrowserModel.observeDefaultBrowserStatus()
        }
    }
}
