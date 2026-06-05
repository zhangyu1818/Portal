import Foundation
@testable import Portal
import Testing

@Suite("DefaultRuleEngine")
struct DefaultRuleEngineTests {
    private let engine = DefaultRuleEngine()

    private func domainRule(pattern: String, enabled: Bool = true) -> Rule {
        .domain(DomainRule(pattern: pattern, browserBundleID: "com.apple.safari", enabled: enabled))
    }

    private func sourceAppRule(bundleID: String, enabled: Bool = true) -> Rule {
        .sourceApp(SourceAppRule(sourceBundleID: bundleID, browserBundleID: "com.apple.safari", enabled: enabled))
    }

    @Test("Empty rules returns noMatch")
    func emptyRulesNoMatch() throws {
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: []) == .noMatch)
    }

    @Test("Matching enabled domain rule returns that rule")
    func domainRuleHit() throws {
        let rule = self.domainRule(pattern: "example.com")
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [rule]) == .rule(rule))
    }

    @Test("Non-matching domain rule returns noMatch")
    func domainRuleMismatch() throws {
        let rule = self.domainRule(pattern: "other.com")
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [rule]) == .noMatch)
    }

    @Test("Disabled domain rule is skipped even when pattern matches")
    func disabledDomainRuleSkipped() throws {
        let rule = self.domainRule(pattern: "example.com", enabled: false)
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [rule]) == .noMatch)
    }

    @Test("Matching enabled source app rule returns that rule")
    func sourceAppRuleHit() throws {
        let rule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap")
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [rule]) == .rule(rule))
    }

    @Test("Source app rule with different bundle id returns noMatch")
    func sourceAppRuleMismatch() throws {
        let rule = self.sourceAppRule(bundleID: "com.apple.mail")
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [rule]) == .noMatch)
    }

    @Test("Source app rule with nil sourceApp returns noMatch")
    func sourceAppRuleNilSourceApp() throws {
        let rule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap")
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [rule]) == .noMatch)
    }

    @Test("Disabled source app rule is skipped even when bundle id matches")
    func disabledSourceAppRuleSkipped() throws {
        let rule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap", enabled: false)
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [rule]) == .noMatch)
    }

    @Test("First matching rule wins when multiple rules match")
    func priorityShortCircuit() throws {
        let first = self.domainRule(pattern: "example.com")
        let second = self.domainRule(pattern: "example.com")
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [first, second]) == .rule(first))
        #expect(self.engine.evaluate(input, against: [second, first]) == .rule(second))
    }

    @Test("First disabled rule is skipped and second enabled rule is returned")
    func firstDisabledSecondEnabled() throws {
        let disabled = self.domainRule(pattern: "example.com", enabled: false)
        let enabled = self.domainRule(pattern: "example.com", enabled: true)
        let url = try #require(URL(string: "https://example.com"))
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [disabled, enabled]) == .rule(enabled))
    }

    @Test("Domain rule wins over a matching source-app rule regardless of array order")
    func domainBeatsSourceAppRegardlessOfOrder() throws {
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let domain = self.domainRule(pattern: "example.com")
        let appRule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap")
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [appRule, domain]) == .rule(domain))
        #expect(self.engine.evaluate(input, against: [domain, appRule]) == .rule(domain))
    }

    @Test("Source-app rule only applies when no domain rule matches")
    func sourceAppOnlyWhenAllDomainsMiss() throws {
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let nonMatchingDomain = self.domainRule(pattern: "other.com")
        let appRule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap")
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [nonMatchingDomain, appRule]) == .rule(appRule))
    }

    @Test("More specific domain rule beats less specific one regardless of array order")
    func specificDomainBeatsWildcard() throws {
        let url = try #require(URL(string: "https://mail.example.com"))
        let exact = self.domainRule(pattern: "mail.example.com")
        let wildcard = self.domainRule(pattern: "*.example.com")
        let input = RoutingInput(url: url)
        #expect(self.engine.evaluate(input, against: [wildcard, exact]) == .rule(exact))
        #expect(self.engine.evaluate(input, against: [exact, wildcard]) == .rule(exact))
    }

    @Test("All disabled rules return noMatch")
    func allDisabledRulesNoMatch() throws {
        let url = try #require(URL(string: "https://example.com"))
        let source = SourceApp(bundleIdentifier: "com.tinyspeck.slackmacgap", displayName: "Slack")
        let domain = self.domainRule(pattern: "example.com", enabled: false)
        let appRule = self.sourceAppRule(bundleID: "com.tinyspeck.slackmacgap", enabled: false)
        let input = RoutingInput(url: url, sourceApp: source)
        #expect(self.engine.evaluate(input, against: [domain, appRule]) == .noMatch)
    }
}
