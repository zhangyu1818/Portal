import AppKit
import SwiftUI

struct SourceAppRuleSheet: View {
    let initialRule: SourceAppRule?
    let browserBundleID: String
    let onSave: (Rule) -> Void
    let onCancel: () -> Void
    let onDelete: ((Rule) -> Void)?

    @State private var sourceBundleID: String
    @State private var sourceDisplayName: String
    @State private var enabled: Bool
    @State private var isPickerPresented = false
    private let ruleID: UUID

    init(
        initialRule: SourceAppRule?,
        browserBundleID: String,
        onSave: @escaping (Rule) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: ((Rule) -> Void)?
    ) {
        self.initialRule = initialRule
        self.browserBundleID = browserBundleID
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        self.ruleID = initialRule?.id ?? UUID()
        self._sourceBundleID = State(initialValue: initialRule?.sourceBundleID ?? "")
        self._sourceDisplayName = State(
            initialValue: Self.lookupDisplayName(for: initialRule?.sourceBundleID) ?? ""
        )
        self._enabled = State(initialValue: initialRule?.enabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(
                        String(localized: "Source App", comment: "Label for source app selector row")
                    ) {
                        self.sourcePickerButton
                    }
                    Toggle(
                        String(localized: "Enabled", comment: "Toggle label for enabling a rule"),
                        isOn: self.$enabled
                    )
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(self.title))
            .toolbar { self.toolbar }
        }
        .frame(minWidth: 460, minHeight: 320)
    }
}

private extension SourceAppRuleSheet {
    var title: LocalizedStringResource {
        self.initialRule == nil
            ? LocalizedStringResource("New rule", comment: "Sheet title when creating a source-app rule")
            : LocalizedStringResource("Edit rule", comment: "Sheet title when editing a source-app rule")
    }

    var isSaveEnabled: Bool {
        !self.sourceBundleID.isEmpty
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(
                String(localized: "Cancel", comment: "Cancel button in source app rule sheet"),
                action: self.onCancel
            )
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(
                String(localized: "Save", comment: "Save button in source app rule sheet"),
                action: self.handleSave
            )
            .disabled(!self.isSaveEnabled)
        }
        if self.initialRule != nil, self.onDelete != nil {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    if let initialRule = self.initialRule {
                        self.onDelete?(.sourceApp(initialRule))
                    }
                } label: {
                    Text("Delete", comment: "Delete button in source app rule sheet")
                }
            }
        }
    }

    var sourcePickerButton: some View {
        Button {
            self.isPickerPresented = true
        } label: {
            HStack(spacing: 8) {
                if !self.sourceBundleID.isEmpty {
                    self.sourceIcon
                    Text(self.sourceDisplayName.isEmpty ? self.sourceBundleID : self.sourceDisplayName)
                        .foregroundStyle(.primary)
                } else {
                    Text("Choose…", comment: "Placeholder when no source app is selected")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .popover(isPresented: self.$isPickerPresented, arrowEdge: .bottom) {
            AppPicker(isPresented: self.$isPickerPresented) { selection in
                self.sourceBundleID = selection.bundleID
                self.sourceDisplayName = selection.displayName
            }
        }
    }

    @ViewBuilder
    var sourceIcon: some View {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.sourceBundleID)
        if let url {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
        }
    }

    func handleSave() {
        let rule = SourceAppRule(
            id: self.ruleID,
            sourceBundleID: self.sourceBundleID,
            browserBundleID: self.browserBundleID,
            enabled: self.enabled,
            createdAt: self.initialRule?.createdAt ?? .now
        )
        self.onSave(.sourceApp(rule))
    }

    static func lookupDisplayName(for bundleID: String?) -> String? {
        guard let bundleID,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let bundle = Bundle(url: url) else { return nil }
        return (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
    }
}
