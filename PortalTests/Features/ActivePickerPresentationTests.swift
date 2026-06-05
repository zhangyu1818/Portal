@testable import Portal
import Testing

@Suite("ActivePickerPresentation")
@MainActor
struct ActivePickerPresentationTests {
    @Test("replacing an active presentation dismisses only the previous presentation")
    func replacingActivePresentationDismissesOnlyPreviousPresentation() {
        let presentation = ActivePickerPresentation()
        var dismissed: [String] = []

        let first = presentation.replace { dismissed.append("first") }
        let second = presentation.replace { dismissed.append("second") }

        #expect(dismissed == ["first"])

        presentation.clear(first)
        presentation.dismissActive()

        #expect(dismissed == ["first", "second"])

        presentation.clear(second)
        #expect(presentation.hasActivePresentation == false)
    }
}
