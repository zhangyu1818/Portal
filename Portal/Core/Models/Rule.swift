import Foundation

public enum Rule: Identifiable, Hashable, Sendable {
    case domain(DomainRule)
    case sourceApp(SourceAppRule)

    public var id: UUID {
        switch self {
        case let .domain(rule): rule.id
        case let .sourceApp(rule): rule.id
        }
    }

    public var isEnabled: Bool {
        switch self {
        case let .domain(inner): inner.enabled
        case let .sourceApp(inner): inner.enabled
        }
    }

    public func withEnabled(_ enabled: Bool) -> Rule {
        switch self {
        case var .domain(inner):
            inner.enabled = enabled
            return .domain(inner)
        case var .sourceApp(inner):
            inner.enabled = enabled
            return .sourceApp(inner)
        }
    }
}

extension Rule: Codable {
    private enum TypeKey: String, Codable {
        case domain
        case sourceApp
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case rule
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeKey = try container.decode(TypeKey.self, forKey: .type)
        switch typeKey {
        case .domain:
            let inner = try container.decode(DomainRule.self, forKey: .rule)
            self = .domain(inner)
        case .sourceApp:
            let inner = try container.decode(SourceAppRule.self, forKey: .rule)
            self = .sourceApp(inner)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .domain(inner):
            try container.encode(TypeKey.domain, forKey: .type)
            try container.encode(inner, forKey: .rule)
        case let .sourceApp(inner):
            try container.encode(TypeKey.sourceApp, forKey: .type)
            try container.encode(inner, forKey: .rule)
        }
    }
}
