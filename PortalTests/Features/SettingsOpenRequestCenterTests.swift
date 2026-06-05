@testable import Portal
import Testing

@Suite("SettingsOpenRequestCenter")
@MainActor
struct SettingsOpenRequestCenterTests {
    @Test("request before install runs when openSettings action becomes available")
    func requestBeforeInstallRunsWhenActionBecomesAvailable() {
        let center = SettingsOpenRequestCenter()
        var callCount = 0

        center.openSettings()
        #expect(callCount == 0)

        center.install {
            callCount += 1
        }

        #expect(callCount == 1)
    }

    @Test("request after install runs immediately")
    func requestAfterInstallRunsImmediately() {
        let center = SettingsOpenRequestCenter()
        var callCount = 0
        center.install {
            callCount += 1
        }

        center.openSettings()

        #expect(callCount == 1)
    }
}
