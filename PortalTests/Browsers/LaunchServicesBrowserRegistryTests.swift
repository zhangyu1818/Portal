import Foundation
@testable import Portal
import Testing

@Suite("LaunchServicesBrowserRegistry")
struct LaunchServicesBrowserRegistryTests {
    @Test("current() returns at least one browser on a developer Mac", .tags(.integration))
    func currentReturnsNonEmpty() async {
        let registry = LaunchServicesBrowserRegistry()
        let browsers = await registry.current()
        #expect(!browsers.isEmpty)
    }

    @Test("browsers are sorted case-insensitively by displayName", .tags(.integration))
    func browsersAreSorted() async {
        let registry = LaunchServicesBrowserRegistry()
        let browsers = await registry.current()
        guard browsers.count > 1 else { return }
        for index in browsers.indices.dropLast() {
            let lhs = browsers[index].displayName
            let rhs = browsers[index + 1].displayName
            #expect(lhs.localizedCaseInsensitiveCompare(rhs) != .orderedDescending)
        }
    }
}
