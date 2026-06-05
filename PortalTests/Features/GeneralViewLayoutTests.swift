@testable import Portal
import Testing

@Suite("GeneralView layout")
struct GeneralViewLayoutTests {
    @Test("version is rendered as footer note")
    func versionIsFooterNote() {
        #expect(GeneralView.versionPlacement == .footerNote)
    }

    @Test("menu bar icon row has no description")
    func menuBarIconRowHasNoDescription() {
        #expect(GeneralView.includesMenuBarIconDescription == false)
    }
}
