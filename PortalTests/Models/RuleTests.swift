import Foundation
@testable import Portal
import Testing

@Suite("Rule")
struct RuleTests {
    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    @Test("Rule.domain Codable round-trip with type discriminator")
    func domainRuleRoundTrip() throws {
        let inner = DomainRule(
            id: UUID(),
            pattern: "example.com",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let rule = Rule.domain(inner)
        let data = try makeEncoder().encode(rule)
        let raw = try JSONSerialization.jsonObject(with: data)
        let json = try #require(raw as? [String: Any])
        #expect(json["type"] as? String == "domain")
        let ruleDict = try #require(json["rule"] as? [String: Any])
        #expect(ruleDict["pattern"] as? String == "example.com")
        let decoded = try makeDecoder().decode(Rule.self, from: data)
        #expect(decoded == rule)
    }

    @Test("Rule.sourceApp Codable round-trip with type discriminator")
    func sourceAppRuleRoundTrip() throws {
        let inner = SourceAppRule(
            id: UUID(),
            sourceBundleID: "com.tinyspeck.slackmacgap",
            browserBundleID: "com.google.Chrome",
            enabled: false,
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        )
        let rule = Rule.sourceApp(inner)
        let data = try makeEncoder().encode(rule)
        let raw = try JSONSerialization.jsonObject(with: data)
        let json = try #require(raw as? [String: Any])
        #expect(json["type"] as? String == "sourceApp")
        let ruleDict = try #require(json["rule"] as? [String: Any])
        #expect(ruleDict["sourceBundleID"] as? String == "com.tinyspeck.slackmacgap")
        let decoded = try makeDecoder().decode(Rule.self, from: data)
        #expect(decoded == rule)
    }

    @Test("Decoding JSON with missing type field throws keyNotFound")
    func missingTypeFieldThrows() {
        let badJSON = #"{"rule":{"id":"00000000-0000-0000-0000-000000000000"}}"#
        let data = Data(badJSON.utf8)
        #expect {
            try makeDecoder().decode(Rule.self, from: data)
        } throws: { error in
            guard let decodingError = error as? DecodingError else { return false }
            if case .keyNotFound = decodingError { return true }
            return false
        }
    }

    @Test("Decoding JSON with unknown type value throws dataCorrupted")
    func unknownTypeValueThrows() {
        let badJSON = #"{"type":"unknown","rule":{}}"#
        let data = Data(badJSON.utf8)
        #expect {
            try makeDecoder().decode(Rule.self, from: data)
        } throws: { error in
            guard let decodingError = error as? DecodingError else { return false }
            if case .dataCorrupted = decodingError { return true }
            return false
        }
    }

    @Test("Rule.id returns inner rule id for domain case")
    func domainRuleIDDelegates() {
        let inner = DomainRule(
            id: UUID(),
            pattern: "example.com",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: Date()
        )
        let rule = Rule.domain(inner)
        #expect(rule.id == inner.id)
    }

    @Test("Rule.id returns inner rule id for sourceApp case")
    func sourceAppRuleIDDelegates() {
        let inner = SourceAppRule(
            id: UUID(),
            sourceBundleID: "com.apple.mail",
            browserBundleID: "com.apple.safari",
            enabled: true,
            createdAt: Date()
        )
        let rule = Rule.sourceApp(inner)
        #expect(rule.id == inner.id)
    }
}
