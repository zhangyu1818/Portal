import Foundation
@testable import Portal
import Testing

@Suite("SourceAppRule")
struct SourceAppRuleTests {
    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000.123456)
        let original = SourceAppRule(
            id: id,
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome",
            enabled: true,
            createdAt: createdAt
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(SourceAppRule.self, from: data)
        #expect(decoded == original)
        #expect(decoded.id == original.id)
        #expect(decoded.sourceBundleID == original.sourceBundleID)
        #expect(decoded.browserBundleID == original.browserBundleID)
        #expect(decoded.enabled == original.enabled)
        #expect(decoded.createdAt == original.createdAt)
    }

    @Test("New instance defaults to enabled true with auto id and createdAt")
    func newInstanceDefaults() {
        let before = Date()
        let rule = SourceAppRule(sourceBundleID: "com.apple.mail", browserBundleID: "com.apple.Safari")
        let after = Date()

        #expect(rule.enabled == true)
        #expect(rule.createdAt >= before)
        #expect(rule.createdAt <= after)
        let other = SourceAppRule(sourceBundleID: "com.apple.mail", browserBundleID: "com.apple.Safari")
        #expect(rule.id != other.id)
    }

    @Test("Equal IDs but different sourceBundleIDs are not equal")
    func equalIDDifferentSourceNotEqual() {
        let sharedID = UUID()
        let date = Date()
        let ruleMail = SourceAppRule(
            id: sharedID,
            sourceBundleID: "com.apple.mail",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: date
        )
        let ruleSlack = SourceAppRule(
            id: sharedID,
            sourceBundleID: "com.slack.slack",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: date
        )
        #expect(ruleMail != ruleSlack)
    }
}
