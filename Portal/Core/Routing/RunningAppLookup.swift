import Foundation

public struct RunningAppInfo: Sendable {
    public var bundleIdentifier: String?
    public var localizedName: String?
    public var bundleURL: URL?

    public init(bundleIdentifier: String? = nil, localizedName: String? = nil, bundleURL: URL? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.bundleURL = bundleURL
    }
}

public protocol RunningAppLookup: Sendable {
    func appForPID(_ pid: pid_t) async -> RunningAppInfo?
    func frontmostApp() async -> RunningAppInfo?
}
