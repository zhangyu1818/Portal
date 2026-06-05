import AppKit
@testable import Portal
import Testing

@Suite("AppleEventSourceAppDetector", .tags(.integration))
struct AppleEventSourceAppDetectorTests {
    @MainActor
    private func makeDetector(
        lookup: RunningAppLookup = FakeRunningAppLookup(),
        selfBundleID: String = "com.example.portal"
    ) -> AppleEventSourceAppDetector {
        AppleEventSourceAppDetector(lookup: lookup, selfBundleID: selfBundleID)
    }

    @Test("currentSource is nil when no event has been recorded")
    @MainActor
    func currentSourceIsNilWhenNoEventRecorded() async {
        let detector = self.makeDetector()
        let source = await detector.currentSource()
        #expect(source == nil)
    }

    @Test("currentSource is nil when latest event is stale (older than 2s)")
    @MainActor
    func currentSourceIsNilWhenEventIsStale() async {
        let info = RunningAppInfo(bundleIdentifier: "com.example.app", localizedName: "App")
        let lookup = FakeRunningAppLookup(apps: [42: info])
        let detector = self.makeDetector(lookup: lookup)
        let staleDate = Date(timeIntervalSinceNow: -5)
        detector.injectEventForTesting(pid: 42, at: staleDate)
        let source = await detector.currentSource()
        #expect(source == nil)
    }

    @Test("currentSource returns SourceApp for a recent event with valid bundle ID")
    @MainActor
    func currentSourceReturnsSourceAppForRecentEvent() async {
        let info = RunningAppInfo(bundleIdentifier: "com.tinyspeck.slackmacgap", localizedName: "Slack")
        let lookup = FakeRunningAppLookup(apps: [42: info])
        let detector = self.makeDetector(lookup: lookup)
        detector.injectEventForTesting(pid: 42, at: Date())
        let source = await detector.currentSource()
        #expect(source == SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack"))
    }

    @Test("currentSource normalizes nested helper app events to their containing app")
    @MainActor
    func currentSourceNormalizesNestedHelperAppEventsToContainingApp() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString,
            directoryHint: .isDirectory
        )
        let appURL = rootURL.appending(path: "Slack.app", directoryHint: .isDirectory)
        let helperURL = appURL.appending(path: "Contents/Frameworks/Slack Helper.app", directoryHint: .isDirectory)
        try self.writeInfoPlist(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            bundleName: "Slack",
            appURL: appURL
        )
        try self.writeInfoPlist(
            bundleIdentifier: "com.tinyspeck.slackmacgap.helper",
            bundleName: "Slack Helper",
            appURL: helperURL
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let info = RunningAppInfo(
            bundleIdentifier: "com.tinyspeck.slackmacgap.helper",
            localizedName: "Slack Helper",
            bundleURL: helperURL
        )
        let lookup = FakeRunningAppLookup(apps: [42: info])
        let detector = self.makeDetector(lookup: lookup)
        detector.injectEventForTesting(pid: 42, at: Date())

        let source = await detector.currentSource()

        #expect(source == SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack"))
    }

    @Test("currentSource is nil when the resolved bundle ID matches self")
    @MainActor
    func currentSourceReturnsNilWhenSelfPID() async {
        let selfID = "com.example.portal"
        let info = RunningAppInfo(bundleIdentifier: selfID, localizedName: "Portal")
        let lookup = FakeRunningAppLookup(apps: [99: info])
        let detector = self.makeDetector(lookup: lookup, selfBundleID: selfID)
        detector.injectEventForTesting(pid: 99, at: Date())
        let source = await detector.currentSource()
        #expect(source == nil)
    }

    @Test("currentSource is nil when the app lookup returns nil for the stored PID")
    @MainActor
    func currentSourceReturnsNilWhenResolverFails() async {
        let lookup = FakeRunningAppLookup(apps: [:])
        let detector = self.makeDetector(lookup: lookup)
        detector.injectEventForTesting(pid: 77, at: Date())
        let source = await detector.currentSource()
        #expect(source == nil)
    }

    @Test("currentSource falls back to frontmost app when no event is recorded")
    @MainActor
    func currentSourceFallsBackToFrontmostApp() async {
        let frontmost = RunningAppInfo(bundleIdentifier: "com.apple.mail", localizedName: "Mail")
        let lookup = FakeRunningAppLookup(apps: [:], frontmost: frontmost)
        let detector = self.makeDetector(lookup: lookup)
        let source = await detector.currentSource()
        #expect(source == SourceApp(bundleIdentifier: "com.apple.mail", displayName: "Mail"))
    }

    private func writeInfoPlist(bundleIdentifier: String, bundleName: String, appURL: URL) throws {
        let contentsURL = appURL.appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": bundleName,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contentsURL.appending(path: "Info.plist"))
    }
}

private struct FakeRunningAppLookup: RunningAppLookup {
    private let apps: [pid_t: RunningAppInfo]
    private let frontmostInfo: RunningAppInfo?

    init(apps: [pid_t: RunningAppInfo] = [:], frontmost: RunningAppInfo? = nil) {
        self.apps = apps
        self.frontmostInfo = frontmost
    }

    func appForPID(_ pid: pid_t) async -> RunningAppInfo? {
        self.apps[pid]
    }

    func frontmostApp() async -> RunningAppInfo? {
        self.frontmostInfo
    }
}
