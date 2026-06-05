import AppKit
import Foundation
import Sparkle

@MainActor
protocol SoftwareUpdateMenuProviding: AnyObject {
    func makeSoftwareUpdateMenuItem() -> NSMenuItem?
}

@MainActor
final class SparkleSoftwareUpdateMenuProvider: SoftwareUpdateMenuProviding {
    private let updaterController: SPUStandardUpdaterController
    private let userDriverDelegate: SparkleMenuBarUserDriverDelegate

    private init(
        updaterController: SPUStandardUpdaterController,
        userDriverDelegate: SparkleMenuBarUserDriverDelegate
    ) {
        self.updaterController = updaterController
        self.userDriverDelegate = userDriverDelegate
    }

    static func makeConfigured(bundle: Bundle = .main) -> SparkleSoftwareUpdateMenuProvider? {
        guard self.hasUsableConfiguration(in: bundle) else {
            return nil
        }

        let userDriverDelegate = SparkleMenuBarUserDriverDelegate()
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: userDriverDelegate
        )
        return SparkleSoftwareUpdateMenuProvider(
            updaterController: controller,
            userDriverDelegate: userDriverDelegate
        )
    }

    func makeSoftwareUpdateMenuItem() -> NSMenuItem? {
        NSMenuItem(
            title: String(localized: "Check for Updates…", comment: "Menu bar item that checks for app updates"),
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        ).configured(target: self.updaterController)
    }

    private static func hasUsableConfiguration(in bundle: Bundle) -> Bool {
        guard let feedURLString = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String else {
            return false
        }
        guard let feedURL = URL(string: feedURLString), feedURL.scheme == "https" else {
            return false
        }
        guard let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }
        return Data(base64Encoded: publicKey) != nil
    }
}

@MainActor
private final class SparkleMenuBarUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _: Bool,
        forUpdate _: SUAppcastItem,
        state _: SPUUserUpdateState
    ) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func standardUserDriverWillFinishUpdateSession() {
        NSApp.setActivationPolicy(.accessory)
    }
}

private extension NSMenuItem {
    func configured(target: AnyObject) -> NSMenuItem {
        self.target = target
        return self
    }
}
