import Foundation
@testable import Portal
import Testing

@Suite("DomainMatcher")
struct DomainMatcherTests {
    @Test("Exact match: host equals pattern")
    func exactMatch() throws {
        let url = try #require(URL(string: "https://example.com/path"))
        #expect(DomainMatcher.matches(url, pattern: "example.com") == true)
    }

    @Test("Exact mismatch: different host")
    func exactMismatch() throws {
        let url = try #require(URL(string: "https://other.com"))
        #expect(DomainMatcher.matches(url, pattern: "example.com") == false)
    }

    @Test("Exact pattern does not match subdomain")
    func exactPatternDoesNotMatchSubdomain() throws {
        let url = try #require(URL(string: "https://foo.example.com"))
        #expect(DomainMatcher.matches(url, pattern: "example.com") == false)
    }

    @Test("Wildcard matches direct subdomain")
    func wildcardMatchesSubdomain() throws {
        let url = try #require(URL(string: "https://foo.example.com"))
        #expect(DomainMatcher.matches(url, pattern: "*.example.com") == true)
    }

    @Test("Wildcard matches deep subdomain")
    func wildcardMatchesDeepSubdomain() throws {
        let url = try #require(URL(string: "https://a.b.example.com"))
        #expect(DomainMatcher.matches(url, pattern: "*.example.com") == true)
    }

    @Test("Wildcard does not match apex domain")
    func wildcardDoesNotMatchApex() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "*.example.com") == false)
    }

    @Test("Case insensitive host comparison")
    func caseInsensitiveHost() throws {
        let url = try #require(URL(string: "https://EXAMPLE.com"))
        #expect(DomainMatcher.matches(url, pattern: "example.com") == true)
    }

    @Test("Case insensitive pattern comparison")
    func caseInsensitivePattern() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "EXAMPLE.com") == true)
    }

    @Test("No host returns false")
    func noHostReturnsFalse() throws {
        let url = try #require(URL(string: "mailto:test@example.com"))
        #expect(DomainMatcher.matches(url, pattern: "example.com") == false)
    }

    @Test("Empty pattern returns false")
    func emptyPatternReturnsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "") == false)
    }

    @Test("Whitespace-only pattern returns false")
    func whitespacePatternReturnsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "   ") == false)
    }

    @Test("Invalid mid-glob pattern returns false")
    func invalidMidGlobReturnsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "foo.*.com") == false)
    }

    @Test("Invalid leading-dot pattern returns false")
    func invalidLeadingDotReturnsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: ".example.com") == false)
    }

    @Test("Whitespace around pattern is trimmed")
    func trimWhitespace() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: " example.com ") == true)
    }

    @Test("Wildcard with empty suffix returns false")
    func wildcardEmptySuffixReturnsFalse() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(DomainMatcher.matches(url, pattern: "*.") == false)
    }

    @Test("Wildcard empty suffix does not match trailing dot host")
    func wildcardEmptySuffixRejectsTrailingDotHost() throws {
        let url = try #require(URL(string: "https://example.com./path"))
        #expect(DomainMatcher.matches(url, pattern: "*.") == false)
    }

    @Test("Leading-dot host does not match wildcard")
    func leadingDotHostRejected() throws {
        let url = try #require(URL(string: "https://.example.com"))
        #expect(DomainMatcher.matches(url, pattern: "*.example.com") == false)
    }

    @Test("IDN unicode pattern matches IDN unicode host")
    func idnUnicodeRoundTrip() throws {
        let url = try #require(URL(string: "https://例子.中国/path"))
        #expect(DomainMatcher.matches(url, pattern: "例子.中国"))
    }

    @Test("IDN unicode pattern matches punycode host")
    func idnUnicodePatternMatchesPunycodeHost() throws {
        let url = try #require(URL(string: "https://xn--fsqu00a.xn--fiqs8s/path"))
        #expect(DomainMatcher.matches(url, pattern: "例子.中国"))
    }

    @Test("Trailing-dot host matches apex pattern")
    func trailingDotHostMatchesApex() throws {
        let url = try #require(URL(string: "https://example.com./path"))
        #expect(DomainMatcher.matches(url, pattern: "example.com"))
    }

    @Test("Trailing-dot host matches wildcard pattern")
    func trailingDotHostMatchesWildcard() throws {
        let url = try #require(URL(string: "https://foo.example.com./path"))
        #expect(DomainMatcher.matches(url, pattern: "*.example.com"))
    }

    @Test("Punycode host matches identical punycode pattern")
    func punycodeHost() throws {
        let url = try #require(URL(string: "https://xn--bcher-kva.example.com/path"))
        #expect(DomainMatcher.matches(url, pattern: "xn--bcher-kva.example.com"))
    }

    @Test("Host with port still matches apex pattern (port stripped)")
    func hostWithPort() throws {
        let url = try #require(URL(string: "https://example.com:8080/path"))
        #expect(DomainMatcher.matches(url, pattern: "example.com"))
    }

    @Test("IPv4 literal matches itself exactly")
    func ipv4HostExactMatch() throws {
        let url = try #require(URL(string: "http://192.168.1.1/admin"))
        #expect(DomainMatcher.matches(url, pattern: "192.168.1.1"))
    }
}
