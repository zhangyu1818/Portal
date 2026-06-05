import Foundation

extension URLRouter {
    func describe(_ sourceApp: SourceApp?) -> String {
        guard let sourceApp else { return "nil" }
        return "\(sourceApp.bundleIdentifier)(\(sourceApp.displayName))"
    }

    func describe(_ match: RuleMatch) -> String {
        switch match {
        case let .rule(rule): "rule(\(self.describe(rule)))"
        case .noMatch: "noMatch"
        }
    }

    func describe(_ rules: [Rule]) -> String {
        rules.map { self.describe($0) }.joined(separator: ",")
    }

    func describe(_ urls: [URL]) -> String {
        urls.map(\.absoluteString).joined(separator: ",")
    }

    func describe(_ browsers: [Browser]) -> String {
        browsers.map(\.bundleIdentifier).joined(separator: ",")
    }

    func describe(_ rule: Rule) -> String {
        switch rule {
        case let .domain(rule):
            "domain(pattern=\(rule.pattern),browser=\(rule.browserBundleID),enabled=\(rule.enabled))"
        case let .sourceApp(rule):
            "sourceApp(source=\(rule.sourceBundleID),browser=\(rule.browserBundleID),enabled=\(rule.enabled))"
        }
    }

    func logLaunch(
        status: String,
        url: URL,
        browser: String,
        error: (any Error)? = nil
    ) {
        var fields = [
            ("status", status),
            ("url", url.absoluteString),
            ("browser", browser),
        ]
        if let error {
            fields.append(("error", String(describing: error)))
        }
        PortalDebugLog.route("router.launch", fields)
    }
}
