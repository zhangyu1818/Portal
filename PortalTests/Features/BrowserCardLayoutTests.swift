import CoreGraphics
@testable import Portal
import Testing

@Suite("BrowserCard layout")
struct BrowserCardLayoutTests {
    @Test("rule list leading inset follows app icon width")
    func ruleListLeadingInsetFollowsAppIconWidth() {
        #expect(BrowserCard.ruleListLeadingInset == BrowserCard.headerIconSize + BrowserCard.headerIconToTitleSpacing)
    }

    @Test("rule rows indent so their content aligns under the browser title")
    func ruleRowsIndentUnderBrowserTitle() {
        #expect(BrowserCard.rowContentInset < BrowserCard.ruleListLeadingInset)
        #expect(BrowserCard.ruleListLeadingInset - BrowserCard.rowContentInset > 0)
    }

    @Test("card owns its own padding and neutral hover styling")
    func cardOwnsPaddingAndNeutralHoverStyling() {
        #expect(BrowserCard.cardHorizontalPadding > 0)
        #expect(BrowserCard.cardVerticalPadding > 0)
        #expect(BrowserCard.headerMinHeight >= BrowserCard.headerIconSize)
        #expect(BrowserCard.rowHoverBackgroundOpacity > 0)
        #expect(BrowserCard.rowHoverBackgroundOpacity < 1)
    }

    @Test("fallback selector keeps the selected app icon compact")
    func fallbackSelectorKeepsTheSelectedAppIconCompact() {
        #expect(UnmatchedLinksFallbackSection.selectorIconSize <= 18)
        #expect(UnmatchedLinksFallbackSection.selectorHeight >= UnmatchedLinksFallbackSection.selectorIconSize + 10)
        #expect(UnmatchedLinksFallbackSection.selectorWidth >= 160)
        #expect(UnmatchedLinksFallbackSection.sectionMinHeight >= UnmatchedLinksFallbackSection.selectorHeight + 12)
    }
}
