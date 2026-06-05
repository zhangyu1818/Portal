import Foundation

public enum DomainMatcher {
    public static func matches(_ url: URL, pattern: String) -> Bool {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        guard !trimmed.hasPrefix(".") else { return false }

        let asteriskCount = trimmed.filter { $0 == "*" }.count
        let isWildcard = trimmed.hasPrefix("*.")
        guard asteriskCount == 0 || isWildcard else { return false }

        guard let normalizedHost = self.normalizedHost(from: url),
              !normalizedHost.hasPrefix(".") else { return false }

        let normalizedPattern = self.normalizedPattern(trimmed, isWildcard: isWildcard)

        if isWildcard {
            let suffix = String(normalizedPattern.dropFirst(2))
            guard !suffix.isEmpty else { return false }
            return normalizedHost.hasSuffix("." + suffix)
        }
        return normalizedHost == normalizedPattern
    }

    public static func specificity(of pattern: String, for url: URL) -> Int {
        guard self.matches(url, pattern: pattern) else { return 0 }
        let trimmed = pattern.trimmingCharacters(in: .whitespaces).lowercased()
        let isWildcard = trimmed.hasPrefix("*.")
        let labelSource = isWildcard ? String(trimmed.dropFirst(2)) : trimmed
        let labelCount = labelSource.split(separator: ".").count
        let exactBoost = isWildcard ? 0 : 1000
        return exactBoost + labelCount
    }

    private static func normalizedHost(from url: URL) -> String? {
        guard let raw = url.host(percentEncoded: false)?.lowercased(),
              !raw.isEmpty else { return nil }
        var host = raw
        if host.hasSuffix(".") {
            host.removeLast()
        }
        guard !host.isEmpty else { return nil }
        return host
    }

    private static func normalizedPattern(_ trimmed: String, isWildcard: Bool) -> String {
        if isWildcard {
            return "*." + self.unicodeHost(from: String(trimmed.dropFirst(2)))
        }
        return self.unicodeHost(from: trimmed)
    }

    private static func unicodeHost(from segment: String) -> String {
        // Normalize a host segment via URLComponents so a Unicode pattern
        // (例子.中国) and a punycode pattern (xn--fsqu00a.xn--fiqs8s) are
        // compared against URL.host(percentEncoded:false) (which itself is
        // punycode-normalized) on equal footing.
        var components = URLComponents()
        components.scheme = "https"
        components.host = segment
        if let url = components.url, let normalized = url.host(percentEncoded: false)?.lowercased() {
            return normalized
        }
        return segment
    }
}
