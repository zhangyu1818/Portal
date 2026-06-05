import Foundation

public struct Browser: Identifiable, Hashable, Sendable, Codable {
    public var bundleIdentifier: String
    public var displayName: String
    public var bundleURL: URL

    public var id: String {
        self.bundleIdentifier
    }

    public init(bundleIdentifier: String, displayName: String, bundleURL: URL) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.bundleURL = bundleURL
    }
}
