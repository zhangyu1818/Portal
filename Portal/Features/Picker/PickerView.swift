import SwiftUI

public struct PickerView: View {
    @Bindable var viewModel: PickerViewModel
    let onChoose: (PickerChoice) -> Void
    let onDismiss: () -> Void

    private let gridColumns = Array(repeating: GridItem(.fixed(84), spacing: Spacing.s), count: 4)

    public init(
        viewModel: PickerViewModel,
        onChoose: @escaping (PickerChoice) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onChoose = onChoose
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            self.headerSection
            self.browserGrid
            self.rememberToggle
        }
        .padding(Spacing.l)
        .glassEffect(GlassMaterial.popover, in: .rect(cornerRadius: Radius.popover))
        .frame(width: 400)
        .onKeyPress(.escape) {
            self.onDismiss()
            return .handled
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Choose a browser", comment: "Picker popup title asking the user to select a browser")
                .font(.headline)
            Text(self.viewModel.url.absoluteString)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if let sourceApp = self.viewModel.sourceApp {
                Text("From: \(sourceApp.displayName)", comment: "Label showing the app that opened the URL")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var browserGrid: some View {
        Group {
            if self.viewModel.browsers.isEmpty {
                Text(
                    "No browsers found",
                    comment: "Shown in the picker popup when the system has no browsers other than this app installed"
                )
                .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: self.gridColumns, spacing: Spacing.s) {
                    ForEach(self.viewModel.browsers) { browser in
                        BrowserIconButton(browser: browser) {
                            self.onChoose(self.viewModel.choose(browser))
                        }
                    }
                }
            }
        }
    }

    private var rememberToggle: some View {
        Toggle(isOn: self.$viewModel.remember) {
            Text(
                "Remember for this site (R)",
                comment: "Checkbox label to save the browser choice"
            )
            .font(.caption)
        }
        .toggleStyle(.checkbox)
        .keyboardShortcut("r", modifiers: [])
    }
}
