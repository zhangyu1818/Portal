import Foundation
import Observation

@MainActor
@Observable
public final class PickerViewModel {
    public let url: URL
    public let sourceApp: SourceApp?
    public let browsers: [Browser]
    public var remember: Bool = false

    public init(url: URL, sourceApp: SourceApp?, browsers: [Browser]) {
        self.url = url
        self.sourceApp = sourceApp
        self.browsers = browsers
    }

    public func choose(_ browser: Browser) -> PickerChoice {
        PickerChoice(browser: browser, remember: self.remember)
    }
}
