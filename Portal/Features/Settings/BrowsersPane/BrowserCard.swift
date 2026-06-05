import AppKit
import SwiftUI

struct BrowserCard: View {
    static let outerLeading: CGFloat = 24

    static let headerIconSize: CGFloat = 22
    static let headerIconToTitleSpacing: CGFloat = 10
    static var ruleListLeadingInset: CGFloat {
        headerIconSize + headerIconToTitleSpacing
    }

    static let rowIconSize: CGFloat = 16
    static let rowContentInset: CGFloat = 8
    static let rowHeight: CGFloat = 34
    static let rowCornerRadius: CGFloat = 8
    static let rowHoverBackgroundOpacity: CGFloat = 0.08

    static let cardHorizontalPadding: CGFloat = 14
    static let cardVerticalPadding: CGFloat = 10
    static let headerMinHeight: CGFloat = 28
    static let headerToRulesGap: CGFloat = 4

    let browser: Browser
    let domainRules: [DomainRule]
    let appRules: [SourceAppRule]
    let onAddDomain: () -> Void
    let onAddSourceApp: () -> Void
    let onEditDomain: (DomainRule) -> Void
    let onDeleteDomain: (DomainRule) -> Void
    let onEditSourceApp: (SourceAppRule) -> Void
    let onDeleteSourceApp: (SourceAppRule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.header
            if !self.isEmpty {
                self.ruleRowsList
                    .padding(.leading, Self.ruleListLeadingInset - Self.rowContentInset)
                    .padding(.top, Self.headerToRulesGap)
            }
        }
        .padding(.horizontal, Self.cardHorizontalPadding)
        .padding(.vertical, Self.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(GlassMaterial.card, in: .rect(cornerRadius: Radius.card))
    }

    private var isEmpty: Bool {
        self.domainRules.isEmpty && self.appRules.isEmpty
    }

    private var header: some View {
        HStack(spacing: Self.headerIconToTitleSpacing) {
            BrowsersAppIcon(url: self.browser.bundleURL, size: Self.headerIconSize)
            Text(self.browser.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            AddRuleMenu(onAddDomain: self.onAddDomain, onAddSourceApp: self.onAddSourceApp)
        }
        .frame(minHeight: Self.headerMinHeight)
    }

    private var ruleRowsList: some View {
        VStack(spacing: 1) {
            ForEach(self.domainRules) { rule in
                BrowsersDomainRuleRow(
                    rule: rule,
                    onEdit: { self.onEditDomain(rule) },
                    onDelete: { self.onDeleteDomain(rule) }
                )
            }
            ForEach(self.appRules) { rule in
                BrowsersSourceAppRuleRow(
                    rule: rule,
                    displayName: BrowsersAppName.resolve(for: rule.sourceBundleID),
                    onEdit: { self.onEditSourceApp(rule) },
                    onDelete: { self.onDeleteSourceApp(rule) }
                )
            }
        }
    }
}

private struct AddRuleMenu: View {
    let onAddDomain: () -> Void
    let onAddSourceApp: () -> Void

    @State private var isHovering = false

    var body: some View {
        Menu {
            Button(action: self.onAddDomain) {
                Label(
                    String(localized: "Domain Rule", comment: "Menu item to add a new domain rule"),
                    systemImage: "link"
                )
            }
            Button(action: self.onAddSourceApp) {
                Label(
                    String(localized: "Source App Rule", comment: "Menu item to add a new source app rule"),
                    systemImage: "app.badge"
                )
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(self.isHovering ? Color(nsColor: .labelColor) : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    self.isHovering ? Color(nsColor: .labelColor).opacity(0.1) : .clear,
                    in: .rect(cornerRadius: 7)
                )
                .contentShape(Rectangle())
                .accessibilityLabel(Text(
                    "Add Rule",
                    comment: "Accessibility label for the add rule button on a browser card"
                ))
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .fixedSize()
        .onHover { self.isHovering = $0 }
        .help(Text("Add Rule", comment: "Tooltip for the add rule button"))
    }
}
