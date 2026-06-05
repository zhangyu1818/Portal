public struct SourceApp: Identifiable, Hashable, Sendable, Codable {
    public var id: String {
        self.bundleIdentifier
    }

    public var bundleIdentifier: String
    public var displayName: String

    public init(bundleIdentifier: String, displayName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}
