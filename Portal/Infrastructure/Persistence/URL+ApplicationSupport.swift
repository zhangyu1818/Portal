import Foundation

extension URL {
    static var applicationSupport: URL {
        get throws {
            try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appending(path: "Portal")
        }
    }
}
