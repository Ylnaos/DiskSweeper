import SwiftUI

@main
struct DiskSweeperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 560)
    }
}
