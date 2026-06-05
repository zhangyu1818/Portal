import Foundation

public protocol BrowserLauncher: Sendable {
    func launch(_ url: URL, in browser: Browser) async throws
}

public enum BrowserLauncherError: Error, Sendable, Equatable {
    case launchFailed(underlying: any Error)
    case browserNotFound(bundleIdentifier: String)

    public static func == (lhs: BrowserLauncherError, rhs: BrowserLauncherError) -> Bool {
        switch (lhs, rhs) {
        case (.launchFailed, .launchFailed): true
        case let (.browserNotFound(lhs), .browserNotFound(rhs)): lhs == rhs
        default: false
        }
    }
}
