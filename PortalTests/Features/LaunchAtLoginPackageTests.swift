import LaunchAtLogin
import SwiftUI
import Testing

@Suite("LaunchAtLogin package")
@MainActor
struct LaunchAtLoginPackageTests {
    @Test("exposes a SwiftUI toggle")
    func exposesSwiftUIToggle() {
        _ = LaunchAtLogin.Toggle {
            Text("Open at login")
        }
    }
}
