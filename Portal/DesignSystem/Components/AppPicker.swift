import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AppPickerSelection: Equatable {
    let bundleID: String
    let displayName: String
}

struct AppPicker: View {
    @Binding var isPresented: Bool
    let onSelect: (AppPickerSelection) -> Void

    @State private var apps: [InstalledApp] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Choose Source App", comment: "AppPicker popover title")
                .font(.headline)
            ScrollView {
                let columns = Array(repeating: GridItem(.fixed(96), spacing: Spacing.s), count: 4)
                LazyVGrid(columns: columns, spacing: Spacing.s) {
                    ForEach(self.apps) { app in
                        Button {
                            let selection = AppPickerSelection(bundleID: app.bundleID, displayName: app.displayName)
                            self.onSelect(selection)
                            self.isPresented = false
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                Text(app.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: 84)
                            }
                            .padding(Spacing.s)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .frame(height: 280)
            HStack {
                Spacer()
                Button(String(
                    localized: "Browse...",
                    comment: "AppPicker button to open NSOpenPanel for full app selection"
                )) {
                    self.browseFromPanel()
                }
            }
        }
        .padding(Spacing.l)
        .frame(width: 460)
        .task {
            self.apps = InstalledAppCatalog.shared.userFacingApps()
        }
    }

    private func browseFromPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        guard panel.runModal() == .OK,
              let url = panel.urls.first,
              let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }
        let displayName = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        self.onSelect(.init(bundleID: bundleID, displayName: displayName))
        self.isPresented = false
    }
}

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let bundleID: String
    let displayName: String
    let icon: NSImage
}

@MainActor
final class InstalledAppCatalog {
    static let shared = InstalledAppCatalog()

    private var cache: [InstalledApp]?

    private init() {}

    func userFacingApps() -> [InstalledApp] {
        if let cache = self.cache { return cache }
        let urls = installedApplicationURLs()
        var apps: [InstalledApp] = []
        let portalBundleID = Bundle.main.bundleIdentifier ?? ""
        for url in urls {
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier,
                  bundleID != portalBundleID,
                  !bundleID.contains(".helper"),
                  !bundleID.contains(".agent") else { continue }
            let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
            apps.append(InstalledApp(id: bundleID, bundleID: bundleID, displayName: name, icon: icon))
        }
        let sorted = apps.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        self.cache = sorted
        return sorted
    }
}

@MainActor
private func installedApplicationURLs() -> [URL] {
    let applicationsRoot = URL(fileURLWithPath: "/Applications", isDirectory: true)
    let resourceKeys: [URLResourceKey] = [.isApplicationKey]
    guard let enumerator = FileManager.default.enumerator(
        at: applicationsRoot,
        includingPropertiesForKeys: resourceKeys,
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else { return [] }
    var urls: [URL] = []
    for case let url as URL in enumerator where url.pathExtension == "app" {
        urls.append(url)
        if urls.count >= 200 { break }
    }
    return urls
}
