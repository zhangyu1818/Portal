import Foundation

enum SettingsPane: String, CaseIterable, Identifiable {
    case browsers
    case general

    var id: String {
        self.rawValue
    }

    var title: LocalizedStringResource {
        switch self {
        case .browsers: LocalizedStringResource(
                "Browsers",
                comment: "Settings sidebar pane for installed browsers and rules"
            )
        case .general: LocalizedStringResource("General", comment: "Settings sidebar pane for general preferences")
        }
    }

    var systemImage: String {
        switch self {
        case .browsers: "globe"
        case .general: "gearshape"
        }
    }
}
