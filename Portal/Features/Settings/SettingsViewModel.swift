import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var selectedPane: SettingsPane = .browsers

    init() {}
}
