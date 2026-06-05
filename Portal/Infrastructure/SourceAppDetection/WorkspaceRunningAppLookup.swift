import AppKit
import Foundation

struct WorkspaceRunningAppLookup: RunningAppLookup {
    func appForPID(_ pid: pid_t) async -> RunningAppInfo? {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        return RunningAppInfo(
            bundleIdentifier: app.bundleIdentifier,
            localizedName: app.localizedName,
            bundleURL: app.bundleURL
        )
    }

    func frontmostApp() async -> RunningAppInfo? {
        let app = await MainActor.run { NSWorkspace.shared.frontmostApplication }
        guard let app else { return nil }
        return RunningAppInfo(
            bundleIdentifier: app.bundleIdentifier,
            localizedName: app.localizedName,
            bundleURL: app.bundleURL
        )
    }
}
