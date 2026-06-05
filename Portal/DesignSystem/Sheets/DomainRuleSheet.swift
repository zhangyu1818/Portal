import SwiftUI

struct DomainRuleSheet: View {
    let initialRule: DomainRule?
    let browserBundleID: String
    let onSave: (Rule) -> Void
    let onCancel: () -> Void
    let onDelete: ((Rule) -> Void)?

    @State private var pattern: String
    @State private var enabled: Bool
    private let ruleID: UUID

    init(
        initialRule: DomainRule?,
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
        self._pattern = State(initialValue: initialRule?.pattern ?? "")
        self._enabled = State(initialValue: initialRule?.enabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "Pattern", comment: "Label for domain pattern field in DomainRuleSheet"),
                        text: self.$pattern,
                        prompt: Text("example.com or *.example.com", comment: "Placeholder for domain pattern")
                    )
                    .monospaced()
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

    private var title: LocalizedStringResource {
        self.initialRule == nil
            ? LocalizedStringResource("New rule", comment: "Sheet title when creating a domain rule")
            : LocalizedStringResource("Edit rule", comment: "Sheet title when editing a domain rule")
    }

    private var isSaveEnabled: Bool {
        !self.pattern.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(
                String(localized: "Cancel", comment: "Cancel button in domain rule sheet"),
                action: self.onCancel
            )
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(
                String(localized: "Save", comment: "Save button in domain rule sheet"),
                action: self.handleSave
            )
            .disabled(!self.isSaveEnabled)
        }
        if self.initialRule != nil, self.onDelete != nil {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    if let initialRule = self.initialRule {
                        self.onDelete?(.domain(initialRule))
                    }
                } label: {
                    Text("Delete", comment: "Delete button in domain rule sheet")
                }
            }
        }
    }

    private func handleSave() {
        let rule = DomainRule(
            id: self.ruleID,
            pattern: self.pattern.trimmingCharacters(in: .whitespaces),
            browserBundleID: self.browserBundleID,
            enabled: self.enabled,
            createdAt: self.initialRule?.createdAt ?? .now
        )
        self.onSave(.domain(rule))
    }
}
