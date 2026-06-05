public protocol BrowserRegistry: Sendable {
    func current() async -> [Browser]
    func observe() async -> AsyncStream<[Browser]>
    func refresh() async
}
