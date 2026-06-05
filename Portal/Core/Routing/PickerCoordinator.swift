import Foundation

public protocol PickerCoordinator: Sendable {
    func presentPicker(
        for url: URL,
        sourceApp: SourceApp?
    ) async -> PickerChoice?
}

public struct PickerChoice: Sendable, Equatable {
    public var browser: Browser
    public var remember: Bool

    public init(browser: Browser, remember: Bool) {
        self.browser = browser
        self.remember = remember
    }
}
