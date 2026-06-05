import Darwin
import Foundation

public protocol SourceAppDetector: Sendable {
    func currentSource() async -> SourceApp?
    func source(forSenderPID pid: pid_t) async -> SourceApp?
}
