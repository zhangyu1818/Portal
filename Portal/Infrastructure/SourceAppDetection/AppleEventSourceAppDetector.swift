import AppKit
import Carbon
import Foundation

@MainActor
public final class AppleEventSourceAppDetector: SourceAppDetector {
    private struct LatestEvent {
        let pid: pid_t
        let timestamp: Date
    }

    private static let staleAfter: TimeInterval = 2.0

    private var latestEvent: LatestEvent?
    private let lookup: RunningAppLookup
    private let selfBundleID: String

    public convenience init() {
        self.init(
            lookup: WorkspaceRunningAppLookup(),
            selfBundleID: Bundle.main.bundleIdentifier ?? ""
        )
    }

    init(lookup: RunningAppLookup, selfBundleID: String) {
        self.lookup = lookup
        self.selfBundleID = selfBundleID
    }

    public func start() {
        PortalDebugLog.route("sourceDetector.start handler=kAEGetURL")
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(self.handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    deinit {
        let eventClass = AEEventClass(kInternetEventClass)
        let eventID = AEEventID(kAEGetURL)
        if Thread.isMainThread {
            NSAppleEventManager.shared().removeEventHandler(
                forEventClass: eventClass,
                andEventID: eventID
            )
        } else {
            DispatchQueue.main.async {
                NSAppleEventManager.shared().removeEventHandler(
                    forEventClass: eventClass,
                    andEventID: eventID
                )
            }
        }
    }

    public func currentSource() async -> SourceApp? {
        if let event = self.latestEvent {
            let age = Date().timeIntervalSince(event.timestamp)
            PortalDebugLog.route("sourceDetector.currentSource latestPID=\(event.pid) age=\(age)")
            if !self.isStale(event) {
                return await self.resolve(pid: event.pid)
            }
            PortalDebugLog.route("sourceDetector.currentSource latestPID stale fallback=frontmost")
        } else {
            PortalDebugLog.route("sourceDetector.currentSource latestPID=nil fallback=frontmost")
        }
        return await self.fallbackToFrontmost()
    }

    public func source(forSenderPID pid: pid_t) async -> SourceApp? {
        PortalDebugLog.route("sourceDetector.sourceForSenderPID", [("pid", "\(pid)")])
        return await self.resolve(pid: pid)
    }

    @objc
    private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent _: NSAppleEventDescriptor) {
        let url = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue ?? "nil"
        guard let pidDescriptor = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr)) else { return }
        let pid = pid_t(pidDescriptor.int32Value)
        guard pid > 0 else { return }
        PortalDebugLog.route("sourceDetector.handleGetURL senderPID=\(pid) url=\(url)")
        self.latestEvent = LatestEvent(pid: pid, timestamp: Date())
    }

    private func isStale(_ event: LatestEvent) -> Bool {
        Date().timeIntervalSince(event.timestamp) > Self.staleAfter
    }

    private func toSourceApp(_ info: RunningAppInfo) -> SourceApp? {
        let info = self.normalizedAppInfo(info)
        guard let bundleID = info.bundleIdentifier,
              !bundleID.isEmpty,
              bundleID != selfBundleID
        else {
            PortalDebugLog.route("sourceDetector.toSourceApp.nil", [
                ("info", self.describe(info)),
                ("selfBundleID", self.selfBundleID),
            ])
            return nil
        }
        let source = SourceApp(
            bundleIdentifier: bundleID,
            displayName: info.localizedName ?? bundleID
        )
        PortalDebugLog.route("sourceDetector.toSourceApp", [
            ("source", source.bundleIdentifier),
            ("name", source.displayName),
            ("info", self.describe(info)),
        ])
        return source
    }

    private func normalizedAppInfo(_ info: RunningAppInfo) -> RunningAppInfo {
        guard let bundleURL = info.bundleURL,
              let containingAppURL = self.outermostApplicationURL(containing: bundleURL),
              containingAppURL.standardizedFileURL != bundleURL.standardizedFileURL,
              let bundle = Bundle(url: containingAppURL),
              let bundleID = bundle.bundleIdentifier,
              !bundleID.isEmpty
        else { return info }

        let normalized = RunningAppInfo(
            bundleIdentifier: bundleID,
            localizedName: self.displayName(from: bundle, fallbackURL: containingAppURL),
            bundleURL: containingAppURL
        )
        PortalDebugLog.route("sourceDetector.normalize", [
            ("from", self.describe(info)),
            ("to", self.describe(normalized)),
        ])
        return normalized
    }

    private func outermostApplicationURL(containing url: URL) -> URL? {
        var current = url.standardizedFileURL
        var candidate: URL?

        while !current.path.isEmpty, current.path != "/" {
            if current.pathExtension == "app" {
                candidate = current
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }

        return candidate
    }

    private func displayName(from bundle: Bundle, fallbackURL: URL) -> String {
        bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleName"] as? String
            ?? fallbackURL.deletingPathExtension().lastPathComponent
    }

    private func describe(_ info: RunningAppInfo) -> String {
        [
            "bundleID:\(info.bundleIdentifier ?? "nil")",
            "name:\(info.localizedName ?? "nil")",
            "bundleURL:\(info.bundleURL?.path() ?? "nil")",
        ].joined(separator: "|")
    }

    private func resolve(pid: pid_t) async -> SourceApp? {
        guard let info = await self.lookup.appForPID(pid) else {
            PortalDebugLog.route("sourceDetector.resolve.nil", [("pid", "\(pid)")])
            return nil
        }
        PortalDebugLog.route("sourceDetector.resolve", [
            ("pid", "\(pid)"),
            ("info", self.describe(info)),
        ])
        return self.toSourceApp(info)
    }

    private func fallbackToFrontmost() async -> SourceApp? {
        guard let info = await self.lookup.frontmostApp() else {
            PortalDebugLog.route("sourceDetector.frontmost.nil")
            return nil
        }
        PortalDebugLog.route("sourceDetector.frontmost", [
            ("info", self.describe(info)),
        ])
        return self.toSourceApp(info)
    }

    func injectEventForTesting(pid: pid_t, at timestamp: Date) {
        self.latestEvent = LatestEvent(pid: pid, timestamp: timestamp)
    }
}
