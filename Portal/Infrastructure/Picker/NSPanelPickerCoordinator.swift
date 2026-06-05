import AppKit
import Foundation

@MainActor
public final class NSPanelPickerCoordinator: PickerCoordinator {
    private let browserRegistry: any BrowserRegistry
    private let activePresentation = ActivePickerPresentation()

    public init(browserRegistry: any BrowserRegistry) {
        self.browserRegistry = browserRegistry
    }

    public func presentPicker(for url: URL, sourceApp: SourceApp?) async -> PickerChoice? {
        let browsers = await self.browserRegistry.current()
        let viewModel = PickerViewModel(url: url, sourceApp: sourceApp, browsers: browsers)
        let cursorLocation = NSEvent.mouseLocation
        self.logRequest(url: url, sourceApp: sourceApp, browsers: browsers, cursorLocation: cursorLocation)

        return await withCheckedContinuation { (continuation: CheckedContinuation<PickerChoice?, Never>) in
            let panel = PickerPanel()
            let resumed = ResumeOnceFlag()
            var presentationID: UUID?

            let resumeOnce: @MainActor (PickerChoice?) -> Void = { choice in
                guard resumed.markResumed() else { return }
                if let presentationID {
                    self.activePresentation.clear(presentationID)
                }
                panel.delegate = nil
                panel.close()
                PortalDebugLog.route("picker.present.resume", [
                    ("url", url.absoluteString),
                    ("choice", choice?.browser.bundleIdentifier ?? "nil"),
                ])
                continuation.resume(returning: choice)
            }

            let bridge = PanelCloseBridge(onClose: { reason in
                PortalDebugLog.route("picker.panel.close", [
                    ("url", url.absoluteString),
                    ("reason", reason.rawValue),
                ])
                resumeOnce(nil)
            })
            panel.delegate = bridge
            if self.activePresentation.hasActivePresentation {
                PortalDebugLog.route("picker.present.replacingExisting", [
                    ("url", url.absoluteString),
                ])
            }
            presentationID = self.activePresentation.replace {
                resumeOnce(nil)
            }

            let view = self.makeView(
                viewModel: viewModel,
                url: url,
                bridge: bridge,
                resumeOnce: resumeOnce
            )

            panel.setContent(view)
            panel.showAt(point: cursorLocation)
        }
    }

    private func describe(_ sourceApp: SourceApp?) -> String {
        guard let sourceApp else { return "nil" }
        return "\(sourceApp.bundleIdentifier)(\(sourceApp.displayName))"
    }

    private func describe(_ browsers: [Browser]) -> String {
        browsers.map(\.bundleIdentifier).joined(separator: ",")
    }

    private func logRequest(
        url: URL,
        sourceApp: SourceApp?,
        browsers: [Browser],
        cursorLocation: CGPoint
    ) {
        PortalDebugLog.route("picker.present.request", [
            ("url", url.absoluteString),
            ("source", self.describe(sourceApp)),
            ("browsers", self.describe(browsers)),
            ("mouse", "\(cursorLocation)"),
        ])
    }

    private func makeView(
        viewModel: PickerViewModel,
        url: URL,
        bridge: PanelCloseBridge,
        resumeOnce: @escaping @MainActor (PickerChoice?) -> Void
    ) -> PickerView {
        PickerView(
            viewModel: viewModel,
            onChoose: { [bridge] choice in
                _ = bridge
                PortalDebugLog.route("picker.choose", [
                    ("url", url.absoluteString),
                    ("browser", choice.browser.bundleIdentifier),
                    ("remember", "\(choice.remember)"),
                ])
                resumeOnce(choice)
            },
            onDismiss: { [bridge] in
                _ = bridge
                PortalDebugLog.route("picker.dismiss.action", [
                    ("url", url.absoluteString),
                ])
                resumeOnce(nil)
            }
        )
    }
}

@MainActor
private final class ResumeOnceFlag {
    private var didResume = false

    func markResumed() -> Bool {
        guard !self.didResume else { return false }
        self.didResume = true
        return true
    }
}

@MainActor
private final class PanelCloseBridge: NSObject, NSWindowDelegate {
    private let onClose: @MainActor (PanelCloseReason) -> Void

    init(onClose: @escaping @MainActor (PanelCloseReason) -> Void) {
        self.onClose = onClose
    }

    nonisolated func windowWillClose(_: Notification) {
        MainActor.assumeIsolated { self.onClose(.willClose) }
    }

    nonisolated func windowDidResignKey(_: Notification) {
        MainActor.assumeIsolated { self.onClose(.didResignKey) }
    }
}

private enum PanelCloseReason: String {
    case willClose
    case didResignKey
}
