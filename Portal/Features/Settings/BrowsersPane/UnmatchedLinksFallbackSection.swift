import SwiftUI

struct UnmatchedLinksFallbackSection: View {
    static let selectorIconSize: CGFloat = 18
    static let selectorHeight: CGFloat = 30
    static let selectorWidth: CGFloat = 184
    static let sectionMinHeight: CGFloat = 46

    let browsers: [Browser]
    let selectedBrowserBundleID: String?
    let onSelectBrowserBundleID: (String?) -> Void

    @State private var isSelectorHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Text("Unmatched Links", comment: "Setting label for links that do not match any routing rule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 12)

            self.selectorMenu
        }
        .padding(.horizontal, BrowserCard.cardHorizontalPadding)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: Self.sectionMinHeight, alignment: .leading)
        .glassEffect(GlassMaterial.card, in: .rect(cornerRadius: Radius.card))
    }

    private var selectorMenu: some View {
        Menu {
            self.menuItem(
                title: String(
                    localized: "Ask Every Time",
                    comment: "Fallback routing option that opens the browser picker"
                ),
                isSelected: self.selectedBrowserBundleID == nil
            ) {
                self.onSelectBrowserBundleID(nil)
            }

            if let unavailableBundleID = self.unavailableSelectedBundleID {
                self.menuItem(
                    title: BrowsersAppName.resolve(for: unavailableBundleID),
                    isSelected: true
                ) {
                    self.onSelectBrowserBundleID(unavailableBundleID)
                }
            }

            ForEach(self.browsers) { browser in
                self.menuItem(
                    title: browser.displayName,
                    isSelected: browser.bundleIdentifier == self.selectedBrowserBundleID
                ) {
                    self.onSelectBrowserBundleID(browser.bundleIdentifier)
                }
            }
        } label: {
            self.selectorLabel
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(Text("Unmatched Links", comment: "Tooltip for unmatched links fallback selector"))
    }

    private var selectorLabel: some View {
        HStack(spacing: 8) {
            self.selectedIcon

            Text(verbatim: self.selectedTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(nsColor: .labelColor))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.leading, 8)
        .padding(.trailing, 7)
        .frame(width: Self.selectorWidth, height: Self.selectorHeight, alignment: .leading)
        .background(
            self.selectorBackground,
            in: .rect(cornerRadius: Radius.control)
        )
        .contentShape(.rect(cornerRadius: Radius.control))
        .onHover { self.isSelectorHovering = $0 }
    }

    @ViewBuilder
    private var selectedIcon: some View {
        if let selectedBrowser {
            BrowsersAppIcon(url: selectedBrowser.bundleURL, size: Self.selectorIconSize)
        } else {
            Image(systemName: self.selectedBrowserBundleID == nil ? "ellipsis.circle" : "questionmark.app")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: Self.selectorIconSize, height: Self.selectorIconSize)
        }
    }

    private var selectorBackground: Color {
        Color(nsColor: .labelColor).opacity(self.isSelectorHovering ? 0.12 : 0.08)
    }

    private var selectedBrowser: Browser? {
        guard let selectedBrowserBundleID else { return nil }
        return self.browsers.first(where: { $0.bundleIdentifier == selectedBrowserBundleID })
    }

    private var selectedTitle: String {
        if let selectedBrowser {
            return selectedBrowser.displayName
        }
        if let selectedBrowserBundleID {
            return BrowsersAppName.resolve(for: selectedBrowserBundleID)
        }
        return String(localized: "Ask Every Time", comment: "Fallback routing option that opens the browser picker")
    }

    private var unavailableSelectedBundleID: String? {
        guard let selectedBrowserBundleID,
              !self.browsers.contains(where: { $0.bundleIdentifier == selectedBrowserBundleID })
        else {
            return nil
        }
        return selectedBrowserBundleID
    }

    private func menuItem(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(verbatim: title)
            }
        }
    }
}
