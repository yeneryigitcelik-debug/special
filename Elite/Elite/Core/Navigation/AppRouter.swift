import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum AuthState {
        case loading
        case unauthenticated
        case waitlist
        case authenticated
    }

    enum Tab: Int, CaseIterable {
        case discovery = 0
        case chat = 1
        case profile = 2
        case settings = 3

        var icon: String {
            switch self {
            case .discovery: return "flame"
            case .chat: return "message"
            case .profile: return "person"
            case .settings: return "gearshape"
            }
        }

        var title: String {
            switch self {
            case .discovery: return "Discover"
            case .chat: return "Messages"
            case .profile: return "Profile"
            case .settings: return "Settings"
            }
        }
    }

    @Published var authState: AuthState = .loading
    @Published var selectedTab: Tab = .discovery
    @Published var showMatch: Match?
    @Published var navigationPath = NavigationPath()

    private let authService = AuthService()

    func checkAuthState() async {
        guard TokenManager.shared.isAuthenticated else {
            authState = .unauthenticated
            return
        }

        do {
            let user = try await authService.refreshSession()
            if user.membershipStatus == .active {
                authState = .authenticated
                WebSocketManager.shared.connect()
                WebSocketManager.shared.startPing()
            } else {
                authState = .waitlist
            }
        } catch {
            TokenManager.shared.clearTokens()
            authState = .unauthenticated
        }
    }

    func signOut() async {
        await authService.signOut()
        authState = .unauthenticated
        selectedTab = .discovery
        navigationPath = NavigationPath()
    }
}
