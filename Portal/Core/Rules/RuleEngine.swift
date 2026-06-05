import Foundation

public struct RoutingInput: Sendable, Equatable {
    public var url: URL
    public var sourceApp: SourceApp?

    public init(url: URL, sourceApp: SourceApp? = nil) {
        self.url = url
        self.sourceApp = sourceApp
    }
}

public enum RuleMatch: Sendable, Equatable {
    case rule(Rule)
    case noMatch
}

public protocol RuleEngine: Sendable {
    func evaluate(_ input: RoutingInput, against rules: [Rule]) -> RuleMatch
}
