import SwiftUI

@main
struct EliteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var router = AppRouter()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.authState {
                case .loading:
                    SplashView()
                case .unauthenticated:
                    OnboardingView()
                case .waitlist:
                    WaitlistView()
                case .authenticated:
                    ContentView()
                }
            }
            .environmentObject(router)
            .environmentObject(networkMonitor)
            .preferredColorScheme(.dark)
            .task {
                await router.checkAuthState()
            }
        }
    }
}
