import Foundation
@testable import Portal
import Testing

@Suite("SourceApp")
struct SourceAppTests {
    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = SourceApp(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            displayName: "Slack"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SourceApp.self, from: data)
        #expect(decoded == original)
        #expect(decoded.bundleIdentifier == original.bundleIdentifier)
        #expect(decoded.displayName == original.displayName)
    }

    @Test("Hashable equality based on all fields")
    func hashableEquality() {
        let mail = SourceApp(bundleIdentifier: "com.apple.mail", displayName: "Mail")
        let mailCopy = SourceApp(bundleIdentifier: "com.apple.mail", displayName: "Mail")
        let mailAlt = SourceApp(bundleIdentifier: "com.apple.mail", displayName: "Apple Mail")
        #expect(mail == mailCopy)
        #expect(mail != mailAlt)
        #expect(Set([mail, mailCopy]).count == 1)
        #expect(Set([mail, mailAlt]).count == 2)
    }
}
