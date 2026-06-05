import AppKit
import CoreServices
import Foundation

actor LaunchServicesDefaultBrowserService: DefaultBrowserService {
    private var continuations: [Int: AsyncStream<DefaultBrowserStatus>.Continuation] = [:]
    private var nextID: Int = 0
    private var pollingTask: Task<Void, Never>?

    deinit {
        self.pollingTask?.cancel()
        for continuation in self.continuations.values {
            continuation.finish()
        }
    }

    nonisolated func currentStatus() async -> DefaultBrowserStatus {
        await resolveStatus()
    }

    @available(macOS, deprecated: 12)
    nonisolated func makePortalDefault() async -> Result<Void, DefaultBrowserError> {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return .failure(.notRegistered)
        }
        let pre = await resolveStatus()
        let httpResult = applyHandler(scheme: "http", bundleID: bundleID)
        if case let .failure(error) = httpResult { return .failure(error) }
        let httpsResult = applyHandler(scheme: "https", bundleID: bundleID)
        if case let .failure(error) = httpsResult { return .failure(error) }

        // Launch Services returns success even when the user dismisses the
        // confirmation prompt, so infer "user declined" by re-querying the
        // current default after both calls succeeded.
        let post = await resolveStatus()
        if post != .isDefault, pre != .isDefault {
            return .failure(.userDeclined)
        }
        return .success(())
    }

    nonisolated func observe() -> AsyncStream<DefaultBrowserStatus> {
        AsyncStream { continuation in
            Task {
                await self.addContinuation(continuation)
            }
        }
    }

    private func addContinuation(_ continuation: AsyncStream<DefaultBrowserStatus>.Continuation) async {
        let id = self.nextID
        self.nextID &+= 1
        self.continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.removeContinuation(id: id) }
        }
        let status = await resolveStatus()
        continuation.yield(status)
        self.ensurePolling()
    }

    private func removeContinuation(id: Int) {
        self.continuations.removeValue(forKey: id)
        if self.continuations.isEmpty {
            self.pollingTask?.cancel()
            self.pollingTask = nil
        }
    }

    private func ensurePolling() {
        guard self.pollingTask == nil else { return }
        self.pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await self?.broadcastCurrentStatus()
            }
        }
    }

    private func broadcastCurrentStatus() async {
        let status = await resolveStatus()
        for continuation in self.continuations.values {
            continuation.yield(status)
        }
    }
}

private extension LaunchServicesDefaultBrowserService {
    nonisolated func resolveStatus() async -> DefaultBrowserStatus {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return .unknown
        }
        guard let probeURL = URL(string: "https://example.com") else {
            return .unknown
        }
        guard let handlerURL = NSWorkspace.shared.urlForApplication(toOpen: probeURL) else {
            return .unknown
        }
        let handler = Bundle(url: handlerURL)?.bundleIdentifier
        guard let handler else {
            return .unknown
        }
        return handler.lowercased() == bundleID.lowercased()
            ? .isDefault
            : .otherBrowser(bundleIdentifier: handler)
    }

    @available(macOS, deprecated: 12)
    nonisolated func applyHandler(scheme: String, bundleID: String) -> Result<Void, DefaultBrowserError> {
        // LSSetDefaultHandlerForURLScheme is deprecated but has no modern replacement
        // for programmatically setting the default browser. Used intentionally.
        let status = LSSetDefaultHandlerForURLScheme(scheme as CFString, bundleID as CFString)
        if status == noErr {
            return .success(())
        }
        // -10814 is kLSApplicationNotFoundErr: this app isn't registered as a
        // URL handler for the requested scheme. It is NOT user decline.
        if status == OSStatus(kLSApplicationNotFoundErr) {
            return .failure(.applicationNotFound)
        }
        return .failure(.launchServicesFailed(status))
    }
}
