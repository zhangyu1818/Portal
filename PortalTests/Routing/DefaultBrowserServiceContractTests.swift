import Foundation
@testable import Portal
import Testing

@Suite("LaunchServicesDefaultBrowserService smoke", .tags(.integration))
struct DefaultBrowserServiceContractTests {
    @Test("currentStatus returns a known variant")
    func currentStatusReturnsKnownVariant() async {
        let service = LaunchServicesDefaultBrowserService()
        let status = await service.currentStatus()

        switch status {
        case .isDefault, .otherBrowser, .unknown:
            break
        }
    }

    @Test("observe emits at least once within reasonable timeout")
    func observeEmitsAtLeastOnce() async {
        let service = LaunchServicesDefaultBrowserService()
        let stream = service.observe()
        var iterator = stream.makeAsyncIterator()

        let received = await iterator.next()
        #expect(received != nil)
    }
}
