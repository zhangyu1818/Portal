import AppKit
import SwiftUI

struct FaviconImage: View {
    let domainPattern: String

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: self.domainPattern) {
            self.image = await FaviconLoader.shared.favicon(forDomainPattern: self.domainPattern)
        }
    }
}
