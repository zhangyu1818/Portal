import Foundation

@MainActor
final class ActivePickerPresentation {
    private var activeID: UUID?
    private var activeDismiss: (@MainActor () -> Void)?

    var hasActivePresentation: Bool {
        self.activeDismiss != nil
    }

    func replace(with dismiss: @escaping @MainActor () -> Void) -> UUID {
        self.activeDismiss?()
        let id = UUID()
        self.activeID = id
        self.activeDismiss = dismiss
        return id
    }

    func clear(_ id: UUID) {
        guard self.activeID == id else { return }
        self.activeID = nil
        self.activeDismiss = nil
    }

    func dismissActive() {
        let dismiss = self.activeDismiss
        self.activeID = nil
        self.activeDismiss = nil
        dismiss?()
    }
}
