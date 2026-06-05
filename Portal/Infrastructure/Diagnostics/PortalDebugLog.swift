import Foundation
import OSLog

enum PortalDebugLog {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Portal",
        category: "Routing"
    )

    static func route(_ message: @autoclosure () -> String) {
        #if DEBUG
            let value = "[PortalDebug] \(message())"
            self.logger.debug("\(value, privacy: .public)")
        #endif
    }

    static func route(_ event: String, _ fields: [(String, String)]) {
        let values = fields.map { "\($0.0)=\($0.1)" }.joined(separator: " ")
        self.route("\(event) \(values)")
    }
}
