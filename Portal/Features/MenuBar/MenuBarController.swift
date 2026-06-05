import AppKit
import Foundation
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let defaults: UserDefaults
    private let defaultBrowserService: any DefaultBrowserService
    private let softwareUpdateMenuProvider: (any SoftwareUpdateMenuProviding)?
    private var statusItem: NSStatusItem?
    private var isObservingDefaults = false

    init(
        defaults: UserDefaults = .standard,
        defaultBrowserService: any DefaultBrowserService = makeDefaultBrowserService(),
        softwareUpdateMenuProvider: (any SoftwareUpdateMenuProviding)? = SparkleSoftwareUpdateMenuProvider
            .makeConfigured()
    ) {
        self.defaults = defaults
        self.defaultBrowserService = defaultBrowserService
        self.softwareUpdateMenuProvider = softwareUpdateMenuProvider
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        if self.isObservingDefaults {
            self.syncVisibility()
            return
        }

        self.isObservingDefaults = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.defaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: self.defaults
        )
        self.syncVisibility()
    }

    private func syncVisibility() {
        if AppPresencePreferences.showsMenuBarIcon(in: self.defaults) {
            self.showStatusItem()
        } else {
            self.hideStatusItem()
        }
    }

    private func showStatusItem() {
        let item = self.statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem = item
        item.menu = self.makeMenu()

        guard let button = item.button else {
            return
        }

        let title = String(localized: "Portal", comment: "Menu bar status item accessibility label")
        let image = NSImage(systemSymbolName: "link", accessibilityDescription: title)
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = title
    }

    private func hideStatusItem() {
        guard let statusItem else {
            return
        }

        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    func makeMenu() -> NSMenu {
        let menu = NSHostingMenu(rootView: MenuBarMenuView(defaultBrowserService: self.defaultBrowserService) {
            NSApp.terminate(nil)
        })
        self.insertSoftwareUpdateItemIfNeeded(in: menu)
        menu.delegate = self
        return menu
    }

    private func insertSoftwareUpdateItemIfNeeded(in menu: NSMenu) {
        guard let updateItem = self.softwareUpdateMenuProvider?.makeSoftwareUpdateMenuItem() else {
            return
        }

        if let quitIndex = menu.items.firstIndex(where: { $0.title == "Quit Portal" }) {
            let insertionIndex = self.updateItemInsertionIndex(in: menu, beforeQuitAt: quitIndex)
            menu.insertItem(updateItem, at: insertionIndex)
        } else {
            menu.addItem(updateItem)
        }
    }

    private func updateItemInsertionIndex(in menu: NSMenu, beforeQuitAt quitIndex: Int) -> Int {
        let separatorIndex = quitIndex - 1
        if separatorIndex >= 0, menu.items[separatorIndex].isSeparatorItem {
            return separatorIndex
        }
        return quitIndex
    }

    func menuWillOpen(_: NSMenu) {
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private nonisolated func defaultsDidChange(_: Notification) {
        Task { @MainActor [weak self] in
            self?.syncVisibility()
        }
    }
}
