import AppKit
import SwiftUI

struct BrowsersView: View {
    @Bindable var viewModel: BrowsersViewModel
    @Bindable var rulesViewModel: RulesViewModel

    @State private var sheet: RuleSheet?

    enum RuleSheet: Identifiable {
        case newDomain(browserBundleID: String)
        case newSourceApp(browserBundleID: String)
        case editDomain(DomainRule)
        case editSourceApp(SourceAppRule)

        var id: String {
            switch self {
            case let .newDomain(id): "newDomain.\(id)"
            case let .newSourceApp(id): "newSourceApp.\(id)"
            case let .editDomain(rule): "editDomain.\(rule.id)"
            case let .editSourceApp(rule): "editSourceApp.\(rule.id)"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                self.unmatchedLinksSection
                    .padding(.bottom, 8)

                if self.viewModel.browsers.isEmpty {
                    Text(
                        "No browsers other than Portal were detected.",
                        comment: "Empty state on Browsers pane"
                    )
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                } else {
                    ForEach(self.sortedBrowsers) { browser in
                        BrowserCard(
                            browser: browser,
                            domainRules: self.domainRules(for: browser),
                            appRules: self.appRules(for: browser),
                            onAddDomain: { self.sheet = .newDomain(browserBundleID: browser.bundleIdentifier) },
                            onAddSourceApp: { self.sheet = .newSourceApp(browserBundleID: browser.bundleIdentifier) },
                            onEditDomain: { self.sheet = .editDomain($0) },
                            onDeleteDomain: { self.delete(.domain($0)) },
                            onEditSourceApp: { self.sheet = .editSourceApp($0) },
                            onDeleteSourceApp: { self.delete(.sourceApp($0)) }
                        )
                    }
                }
            }
            .padding(.horizontal, BrowserCard.outerLeading)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .task {
            await self.viewModel.load()
            await self.viewModel.startObserving()
            await self.rulesViewModel.load()
            await self.rulesViewModel.startObserving()
        }
        .onDisappear {
            self.viewModel.stopObserving()
            self.rulesViewModel.stopObserving()
        }
        .sheet(item: self.$sheet) { sheet in
            self.sheetView(for: sheet)
        }
        .confirmationDialog(
            self.duplicateConfirmTitle,
            isPresented: Binding(
                get: { self.rulesViewModel.pendingDuplicateReplace != nil },
                set: { if !$0 { self.rulesViewModel.cancelDuplicateReplace() } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Replace", comment: "Confirm duplicate replace"), role: .destructive) {
                Task {
                    await self.rulesViewModel.confirmDuplicateReplace()
                    self.sheet = nil
                }
            }
            Button(String(localized: "Cancel", comment: "Cancel duplicate replace"), role: .cancel) {
                self.rulesViewModel.cancelDuplicateReplace()
            }
        }
    }
}

private extension BrowsersView {
    var sortedBrowsers: [Browser] {
        self.viewModel.browsers.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
    }

    var unmatchedLinksSection: some View {
        UnmatchedLinksFallbackSection(
            browsers: self.sortedBrowsers,
            selectedBrowserBundleID: self.viewModel.fallbackBrowserBundleID,
            onSelectBrowserBundleID: { bundleID in
                Task { await self.viewModel.setFallbackBrowserBundleID(bundleID) }
            }
        )
    }

    func domainRules(for browser: Browser) -> [DomainRule] {
        self.rulesViewModel.rules.compactMap { rule in
            guard case let .domain(inner) = rule, inner.browserBundleID == browser.bundleIdentifier else {
                return nil
            }
            return inner
        }
    }

    func appRules(for browser: Browser) -> [SourceAppRule] {
        self.rulesViewModel.rules.compactMap { rule in
            guard case let .sourceApp(inner) = rule, inner.browserBundleID == browser.bundleIdentifier else {
                return nil
            }
            return inner
        }
    }

    func delete(_ rule: Rule) {
        let index = self.rulesViewModel.rules.firstIndex(where: { $0.id == rule.id })
        Task { await self.rulesViewModel.remove(at: index.map(IndexSet.init(integer:)) ?? IndexSet()) }
    }

    var duplicateConfirmTitle: String {
        guard let pending = self.rulesViewModel.pendingDuplicateReplace,
              case let .sourceApp(incoming) = pending.incomingRule
        else {
            return ""
        }
        return String(
            localized: "Replace existing rule for \(BrowsersAppName.resolve(for: incoming.sourceBundleID))?",
            comment: "Confirmation prompt when adding a duplicate source-app rule"
        )
    }

    @ViewBuilder
    func sheetView(for sheet: RuleSheet) -> some View {
        switch sheet {
        case let .newDomain(bundleID):
            DomainRuleSheet(
                initialRule: nil,
                browserBundleID: bundleID,
                onSave: self.saveAndDismiss,
                onCancel: { self.sheet = nil },
                onDelete: nil
            )
        case let .newSourceApp(bundleID):
            SourceAppRuleSheet(
                initialRule: nil,
                browserBundleID: bundleID,
                onSave: self.saveAndDismiss,
                onCancel: { self.sheet = nil },
                onDelete: nil
            )
        case let .editDomain(rule):
            DomainRuleSheet(
                initialRule: rule,
                browserBundleID: rule.browserBundleID,
                onSave: self.updateAndDismiss,
                onCancel: { self.sheet = nil },
                onDelete: { _ in self.deleteAndDismiss(.domain(rule)) }
            )
        case let .editSourceApp(rule):
            SourceAppRuleSheet(
                initialRule: rule,
                browserBundleID: rule.browserBundleID,
                onSave: self.updateAndDismiss,
                onCancel: { self.sheet = nil },
                onDelete: { _ in self.deleteAndDismiss(.sourceApp(rule)) }
            )
        }
    }

    func saveAndDismiss(_ rule: Rule) {
        Task {
            await self.rulesViewModel.add(rule)
            if self.rulesViewModel.pendingDuplicateReplace == nil {
                self.sheet = nil
            }
        }
    }

    func updateAndDismiss(_ rule: Rule) {
        Task { await self.rulesViewModel.update(rule) }
        self.sheet = nil
    }

    func deleteAndDismiss(_ rule: Rule) {
        self.delete(rule)
        self.sheet = nil
    }
}
