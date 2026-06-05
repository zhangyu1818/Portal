import Foundation

protocol DefaultBrowserService: Sendable {
    func currentStatus() async -> DefaultBrowserStatus
    func makePortalDefault() async -> Result<Void, DefaultBrowserError>
    func observe() -> AsyncStream<DefaultBrowserStatus>
}

nonisolated enum DefaultBrowserStatus: Equatable {
    case isDefault
    case otherBrowser(bundleIdentifier: String?)
    case unknown
}

nonisolated enum DefaultBrowserError: Error, Equatable {
    case launchServicesFailed(OSStatus)
    case notRegistered
    case applicationNotFound
    case userDeclined
}
