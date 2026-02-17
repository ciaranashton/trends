import SwiftUI

@main
struct TrendsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var healthManager = HealthManager()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(healthManager: healthManager)
            } else {
                HealthPermissionsView(
                    healthManager: healthManager,
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
            }
        }
    }
}
