import Foundation

public struct SourceAppRule: Identifiable, Hashable, Sendable, Codable {
    public var id: UUID
    public var sourceBundleID: String
    public var browserBundleID: String
    public var enabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sourceBundleID: String,
        browserBundleID: String,
        enabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sourceBundleID = sourceBundleID
        self.browserBundleID = browserBundleID
        self.enabled = enabled
        self.createdAt = createdAt
    }
}
