import Foundation
@testable import Portal
import Testing

@Suite("DomainMatcher specificity")
struct DomainMatcherSpecificityTests {
    @Test("Exact host match scores higher than wildcard for the same URL")
    func exactBeatsWildcard() throws {
        let url = try #require(URL(string: "https://mail.example.com"))
        let exact = DomainMatcher.specificity(of: "mail.example.com", for: url)
        let wildcard = DomainMatcher.specificity(of: "*.example.com", for: url)
        #expect(exact > wildcard)
        #expect(exact > 0)
        #expect(wildcard > 0)
    }

    @Test("Longer exact match outranks shorter exact match for the same URL")
    func longerExactBeatsShorterExact() throws {
        let url = try #require(URL(string: "https://mail.example.com"))
        let longer = DomainMatcher.specificity(of: "mail.example.com", for: url)
        let shorter = DomainMatcher.specificity(of: "example.com", for: url)
        #expect(longer > shorter)
    }

    @Test("Longer wildcard tail outranks shorter wildcard tail for the same URL")
    func longerWildcardTailBeatsShorter() throws {
        let url = try #require(URL(string: "https://a.b.example.com"))
        let longTail = DomainMatcher.specificity(of: "*.b.example.com", for: url)
        let shortTail = DomainMatcher.specificity(of: "*.example.com", for: url)
        #expect(longTail > shortTail)
    }

    @Test("Non-matching pattern returns zero")
    func noMatchReturnsZero() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.specificity(of: "other.com", for: url) == 0)
    }
}
