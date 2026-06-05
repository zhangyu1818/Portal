import AppKit
import Foundation

@MainActor
final class WorkspaceLaunchObserver {
    private var task: Task<Void, Never>?

    init(onChange: @escaping @Sendable () async -> Void) {
        let task = Task { @MainActor in
            let center = NSWorkspace.shared.notificationCenter
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in center.notifications(named: NSWorkspace.didLaunchApplicationNotification) {
                        guard !Task.isCancelled else { return }
                        await onChange()
                    }
                }
                group.addTask {
                    for await _ in center.notifications(named: NSWorkspace.didTerminateApplicationNotification) {
                        guard !Task.isCancelled else { return }
                        await onChange()
                    }
                }
                await group.waitForAll()
            }
        }
        self.task = task
    }

    deinit {
        self.task?.cancel()
    }
}
