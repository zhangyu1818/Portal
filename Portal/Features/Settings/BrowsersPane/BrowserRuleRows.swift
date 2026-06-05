import AppKit
import SwiftUI

struct BrowsersDomainRuleRow: View {
    let rule: DomainRule
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        BrowserRuleRowChrome(
            isEnabled: self.rule.enabled,
            onEdit: self.onEdit,
            onDelete: self.onDelete,
            accessibilityText: self.rule.pattern,
            leadingIcon: { FaviconImage(domainPattern: self.rule.pattern) },
            label: {
                Text(self.rule.pattern)
                    .font(.system(size: 13))
                    .foregroundStyle(self.rule.enabled ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        )
    }
}

struct BrowsersSourceAppRuleRow: View {
    let rule: SourceAppRule
    let displayName: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        BrowserRuleRowChrome(
            isEnabled: self.rule.enabled,
            onEdit: self.onEdit,
            onDelete: self.onDelete,
            accessibilityText: self.displayName,
            leadingIcon: { BrowsersAppIcon(bundleID: self.rule.sourceBundleID, size: 16) },
            label: {
                Text(self.displayName)
                    .font(.system(size: 13))
                    .foregroundStyle(self.rule.enabled ? .primary : .secondary)
                    .lineLimit(1)
            }
        )
    }
}

struct BrowserRuleRowChrome<LeadingIcon: View, Label: View>: View {
    let isEnabled: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let accessibilityText: String
    @ViewBuilder let leadingIcon: () -> LeadingIcon
    @ViewBuilder let label: () -> Label

    @State private var isHovering = false

    var body: some View {
        Button(action: self.onEdit) {
            HStack(spacing: 10) {
                self.leadingIcon()
                    .frame(width: BrowserCard.rowIconSize, height: BrowserCard.rowIconSize)
                    .opacity(self.isEnabled ? 1 : 0.5)
                self.label()
                Spacer(minLength: 8)
                self.trailing
            }
            .padding(.horizontal, BrowserCard.rowContentInset)
            .frame(height: BrowserCard.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                self.isHovering ? Color(nsColor: .labelColor).opacity(BrowserCard.rowHoverBackgroundOpacity) : Color
                    .clear,
                in: .rect(cornerRadius: BrowserCard.rowCornerRadius)
            )
            .contentShape(.rect(cornerRadius: BrowserCard.rowCornerRadius))
        }
        .buttonStyle(.plain)
        .onHover { self.isHovering = $0 }
        .accessibilityLabel(Text(self.accessibilityText))
        .accessibilityHint(Text(
            "Double tap to edit this rule",
            comment: "Accessibility hint for a rule row"
        ))
        .contextMenu {
            Button(String(localized: "Edit", comment: "Context menu — edit rule")) { self.onEdit() }
            Button(
                String(localized: "Delete", comment: "Context menu — delete rule"),
                role: .destructive
            ) { self.onDelete() }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if self.isHovering {
            HStack(spacing: 2) {
                HoverIconButton(
                    systemImage: "pencil",
                    tooltip: LocalizedStringResource("Edit", comment: "Tooltip for the edit button"),
                    action: self.onEdit
                )
                HoverIconButton(
                    systemImage: "trash",
                    tooltip: LocalizedStringResource("Delete", comment: "Tooltip for the delete button"),
                    isDestructive: true,
                    action: self.onDelete
                )
            }
            .transition(.opacity)
        } else if !self.isEnabled {
            Text("Disabled", comment: "Inline label for a disabled rule")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

private struct HoverIconButton: View {
    let systemImage: String
    let tooltip: LocalizedStringResource
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: self.action) {
            Image(systemName: self.systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.foreground)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { self.isHovering = $0 }
        .help(Text(self.tooltip))
    }

    private var foreground: Color {
        if self.isHovering {
            return self.isDestructive ? .red : Color(nsColor: .labelColor)
        }
        return .secondary
    }
}

struct BrowsersAppIcon: View {
    private let url: URL?
    private let size: CGFloat

    init(url: URL?, size: CGFloat = 16) {
        self.url = url
        self.size = size
    }

    init(bundleID: String, size: CGFloat = 16) {
        self.url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        self.size = size
    }

    var body: some View {
        Group {
            if let url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: self.size, height: self.size)
    }
}

enum BrowsersAppName {
    static func resolve(for bundleID: String) -> String {
        guard
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
            let bundle = Bundle(url: url)
        else {
            return bundleID
        }
        return bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleName"] as? String
            ?? bundleID
    }
}
