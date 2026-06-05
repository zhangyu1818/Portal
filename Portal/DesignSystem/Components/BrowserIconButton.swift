import AppKit
import SwiftUI

struct BrowserIconButton: View {
    let browser: Browser
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            VStack(spacing: 4) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: self.browser.bundleURL.path(percentEncoded: false)))
                    .resizable()
                    .frame(width: 44, height: 44)
                Text(self.browser.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            }
            .padding(8)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}
