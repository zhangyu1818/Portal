import AppKit
import Foundation

public actor LaunchServicesBrowserRegistry: BrowserRegistry {
    public typealias Scanner = @Sendable () async -> [Browser]

    private var cachedBrowsers: [Browser]?
    private var continuations: [Int: AsyncStream<[Browser]>.Continuation] = [:]
    private var nextID: Int = 0
    private let scan: Scanner
    private let observerHolder: WorkspaceObserverHolder

    public init(scanner: Scanner? = nil, observeWorkspace: Bool = true) {
        let resolvedScanner: Scanner = scanner ?? { await LaunchServicesBrowserScanner.scan() }
        self.scan = resolvedScanner
        self.observerHolder = WorkspaceObserverHolder()
        if observeWorkspace {
            let holder = self.observerHolder
            Task { [weak self] in
                await holder.attach { [weak self] in
                    guard let self else { return }
                    await self.refresh()
                }
            }
        }
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    public func current() async -> [Browser] {
        if let cached = self.cachedBrowsers {
            return cached
        }
        await self.refresh()
        return self.cachedBrowsers ?? []
    }

    public func observe() async -> AsyncStream<[Browser]> {
        AsyncStream { continuation in
            let id = self.nextID
            self.nextID &+= 1
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.removeContinuation(id: id) }
            }
            if let cached = self.cachedBrowsers {
                continuation.yield(cached)
            }
        }
    }

    public func refresh() async {
        let browsers = await self.scan()
        guard browsers != self.cachedBrowsers else { return }
        self.cachedBrowsers = browsers
        self.fanOut(browsers)
    }

    private func removeContinuation(id: Int) {
        self.continuations.removeValue(forKey: id)
    }

    private func fanOut(_ browsers: [Browser]) {
        for continuation in self.continuations.values {
            continuation.yield(browsers)
        }
    }
}

actor WorkspaceObserverHolder {
    private var observer: WorkspaceLaunchObserver?

    func attach(onChange: @escaping @Sendable () async -> Void) async {
        let observer = await MainActor.run {
            WorkspaceLaunchObserver(onChange: onChange)
        }
        self.observer = observer
    }
}

enum LaunchServicesBrowserScanner {
    @Sendable
    static func scan() async -> [Browser] {
        let httpProbe = httpProbeURL()
        let httpsProbe = httpsProbeURL()
        let httpApps = NSWorkspace.shared.urlsForApplications(toOpen: httpProbe)
        let httpsApps = NSWorkspace.shared.urlsForApplications(toOpen: httpsProbe)
        let combined = httpApps + httpsApps
        let candidates = combined.compactMap(makeBrowser(from:))
        let selfID = Bundle.main.bundleIdentifier ?? ""
        let filtered = BrowserRegistryFilter.filterBrowsers(candidates, excludingSelf: selfID)
        return BrowserRegistryFilter.sort(filtered)
    }
}

private func httpsProbeURL() -> URL {
    guard let url = URL(string: "https://example.com") else {
        preconditionFailure("hardcoded https URL must parse")
    }
    return url
}

private func httpProbeURL() -> URL {
    guard let url = URL(string: "http://example.com") else {
        preconditionFailure("hardcoded http URL must parse")
    }
    return url
}

private func makeBrowser(from appURL: URL) -> Browser? {
    let bundle = Bundle(url: appURL)
    guard let bundleIdentifier = bundle?.bundleIdentifier, !bundleIdentifier.isEmpty else {
        return nil
    }
    let displayName = resolveDisplayName(from: bundle, fallbackURL: appURL)
    return Browser(bundleIdentifier: bundleIdentifier, displayName: displayName, bundleURL: appURL)
}

private func resolveDisplayName(from bundle: Bundle?, fallbackURL: URL) -> String {
    if let name = bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String, !name.isEmpty {
        return name
    }
    if let name = bundle?.infoDictionary?["CFBundleDisplayName"] as? String, !name.isEmpty {
        return name
    }
    if let name = bundle?.infoDictionary?["CFBundleName"] as? String, !name.isEmpty {
        return name
    }
    return fallbackURL.deletingPathExtension().lastPathComponent
}
