import Foundation

public struct DefaultRuleEngine: RuleEngine {
    public init() {}

    public func evaluate(_ input: RoutingInput, against rules: [Rule]) -> RuleMatch {
        if let match = self.matchDomain(input, in: rules) {
            return .rule(match)
        }
        if let match = self.matchSourceApp(input, in: rules) {
            return .rule(match)
        }
        return .noMatch
    }

    private func matchDomain(_ input: RoutingInput, in rules: [Rule]) -> Rule? {
        var best: (rule: Rule, score: Int)?
        for rule in rules {
            guard case let .domain(domainRule) = rule, domainRule.enabled else { continue }
            let score = DomainMatcher.specificity(of: domainRule.pattern, for: input.url)
            guard score > 0 else { continue }
            if let current = best {
                if score > current.score {
                    best = (rule, score)
                }
            } else {
                best = (rule, score)
            }
        }
        return best?.rule
    }

    private func matchSourceApp(_ input: RoutingInput, in rules: [Rule]) -> Rule? {
        guard let sourceBundle = input.sourceApp?.bundleIdentifier else { return nil }
        for rule in rules {
            guard case let .sourceApp(appRule) = rule,
                  appRule.enabled,
                  appRule.sourceBundleID == sourceBundle else { continue }
            return rule
        }
        return nil
    }
}
