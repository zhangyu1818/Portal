import Foundation
@testable import Portal
import Testing

@Suite("DomainRule")
struct DomainRuleTests {
    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000.123456)
        let original = DomainRule(
            id: id,
            pattern: "*.example.com",
            browserBundleID: "com.google.Chrome",
            enabled: true,
            createdAt: createdAt
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(DomainRule.self, from: data)
        #expect(decoded == original)
        #expect(decoded.id == original.id)
        #expect(decoded.pattern == original.pattern)
        #expect(decoded.browserBundleID == original.browserBundleID)
        #expect(decoded.enabled == original.enabled)
        #expect(decoded.createdAt == original.createdAt)
    }

    @Test("New instance defaults to enabled true with auto id and createdAt")
    func newInstanceDefaults() {
        let before = Date()
        let rule = DomainRule(pattern: "example.com", browserBundleID: "com.apple.Safari")
        let after = Date()

        #expect(rule.enabled == true)
        #expect(rule.createdAt >= before)
        #expect(rule.createdAt <= after)
        let other = DomainRule(pattern: "example.com", browserBundleID: "com.apple.Safari")
        #expect(rule.id != other.id)
    }

    @Test("Equal IDs but different patterns are not equal")
    func equalIDDifferentPatternNotEqual() {
        let sharedID = UUID()
        let date = Date()
        let ruleExample = DomainRule(
            id: sharedID,
            pattern: "example.com",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: date
        )
        let ruleOther = DomainRule(
            id: sharedID,
            pattern: "other.com",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: date
        )
        #expect(ruleExample != ruleOther)
    }
}
