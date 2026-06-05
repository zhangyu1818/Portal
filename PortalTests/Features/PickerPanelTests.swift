import AppKit
@testable import Portal
import Testing

@Suite("PickerPanel")
@MainActor
struct PickerPanelTests {
    @Test("panel can become key so outside clicks can dismiss it")
    func panelCanBecomeKeySoOutsideClicksCanDismissIt() {
        let panel = PickerPanel()

        #expect(panel.canBecomeKey == true)
        #expect(panel.becomesKeyOnlyIfNeeded == false)
    }
}
