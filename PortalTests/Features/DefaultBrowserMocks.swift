import Foundation
@testable import Portal

actor MockDefaultBrowserService: DefaultBrowserService {
    private let status: DefaultBrowserStatus
    private let makeDefaultResult: Result<Void, DefaultBrowserError>
    private(set) var makeDefaultCallCount: Int = 0

    init(
        status: DefaultBrowserStatus,
        makeDefaultResult: Result<Void, DefaultBrowserError> = .success(())
    ) {
        self.status = status
        self.makeDefaultResult = makeDefaultResult
    }

    nonisolated func currentStatus() async -> DefaultBrowserStatus {
        await withCheckedContinuation { continuation in
            Task { await continuation.resume(returning: self.getStatus()) }
        }
    }

    nonisolated func makePortalDefault() async -> Result<Void, DefaultBrowserError> {
        await withCheckedContinuation { continuation in
            Task { await continuation.resume(returning: self.callMakeDefault()) }
        }
    }

    nonisolated func observe() -> AsyncStream<DefaultBrowserStatus> {
        AsyncStream<DefaultBrowserStatus> { continuation in
            Task {
                let currentStatus = await self.getStatus()
                continuation.yield(currentStatus)
                continuation.finish()
            }
        }
    }

    private func getStatus() -> DefaultBrowserStatus {
        self.status
    }

    private func callMakeDefault() -> Result<Void, DefaultBrowserError> {
        self.makeDefaultCallCount += 1
        return self.makeDefaultResult
    }
}
