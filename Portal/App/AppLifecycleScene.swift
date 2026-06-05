import SwiftUI

struct AppLifecycleScene: Scene {
    var body: some Scene {
        WindowGroup(Text("Portal", comment: "Hidden lifecycle window title"), id: "portal-lifecycle") {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
    }
}
