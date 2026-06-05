import SwiftUI

struct GlassCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(
        padding: CGFloat = Spacing.l,
        cornerRadius: CGFloat = Radius.card,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        self.content
            .padding(self.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(GlassMaterial.card, in: .rect(cornerRadius: self.cornerRadius))
    }
}
