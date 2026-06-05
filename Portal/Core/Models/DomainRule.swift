import Foundation

public struct DomainRule: Identifiable, Hashable, Sendable, Codable {
    public var id: UUID
    public var pattern: String
    public var browserBundleID: String
    public var enabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        pattern: String,
        browserBundleID: String,
        enabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.pattern = pattern
        self.browserBundleID = browserBundleID
        self.enabled = enabled
        self.createdAt = createdAt
    }
}
