import AppKit
import Foundation

actor FaviconLoader {
    static let shared = FaviconLoader()

    private let cache = NSCache<NSString, NSImage>()
    private var inflight: [String: Task<NSImage?, Never>] = [:]
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
        self.cache.countLimit = 256
    }

    func favicon(forDomainPattern pattern: String) async -> NSImage? {
        guard let host = Self.normalizedHost(for: pattern) else { return nil }
        let key = host as NSString
        if let cached = self.cache.object(forKey: key) {
            return cached
        }
        if let existing = self.inflight[host] {
            return await existing.value
        }
        let task = Task<NSImage?, Never> {
            await self.fetch(host: host)
        }
        self.inflight[host] = task
        let result = await task.value
        self.inflight[host] = nil
        if let result {
            self.cache.setObject(result, forKey: key)
        }
        return result
    }

    private func fetch(host: String) async -> NSImage? {
        for candidate in Self.candidateURLs(for: host) {
            if let image = await self.download(candidate), Self.isReasonable(image) {
                return image
            }
        }
        return nil
    }

    private func download(_ url: URL) async -> NSImage? {
        do {
            let (data, response) = try await self.session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                return nil
            }
            return NSImage(data: data)
        } catch {
            return nil
        }
    }

    static func normalizedHost(for pattern: String) -> String? {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let stripped = trimmed.hasPrefix("*.") ? String(trimmed.dropFirst(2)) : trimmed
        guard stripped.contains(".") else { return nil }
        return stripped
    }

    private static func candidateURLs(for host: String) -> [URL] {
        var urls: [URL] = []
        if let direct = URL(string: "https://\(host)/favicon.ico") {
            urls.append(direct)
        }
        if let www = URL(string: "https://www.\(host)/favicon.ico"), !host.hasPrefix("www.") {
            urls.append(www)
        }
        return urls
    }

    private static func isReasonable(_ image: NSImage) -> Bool {
        let size = image.size
        return size.width >= 8 && size.height >= 8
    }
}
