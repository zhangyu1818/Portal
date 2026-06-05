import SwiftUI

struct InlineWarning: View {
    private let message: LocalizedStringResource
    private let onDismiss: (() -> Void)?

    init(_ message: LocalizedStringResource, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        GlassCard(padding: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(self.message)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let onDismiss = self.onDismiss {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
