import SwiftUI

@main
struct LegacyNestControlApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.makeRootView()
                .environmentObject(coordinator)
        }
    }
}
