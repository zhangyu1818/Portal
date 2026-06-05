import SwiftUI

@MainActor
final class SettingsOpenRequestCenter: SettingsOpening {
    static let shared = SettingsOpenRequestCenter()

    private var openSettingsAction: (@MainActor () -> Void)?
    private var hasPendingRequest = false

    func install(openSettings: @escaping @MainActor () -> Void) {
        self.openSettingsAction = openSettings
        if self.hasPendingRequest {
            self.hasPendingRequest = false
            openSettings()
        }
    }

    func openSettings() {
        guard let openSettingsAction else {
            self.hasPendingRequest = true
            return
        }

        openSettingsAction()
    }
}

struct SettingsOpenAccessScene<Content: Scene>: Scene {
    private let content: Content

    init(
        openSettings: @escaping @MainActor () -> Void,
        @SceneBuilder content: () -> Content
    ) {
        SettingsOpenRequestCenter.shared.install(openSettings: openSettings)
        self.content = content()
    }

    var body: some Scene {
        self.content
    }
}
