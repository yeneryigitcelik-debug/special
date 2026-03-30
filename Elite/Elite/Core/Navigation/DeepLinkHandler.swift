import Foundation

@MainActor
final class DeepLinkHandler: ObservableObject {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }

        switch host {
        case "profile":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                router.selectedTab = .profile
            }
        case "match":
            router.selectedTab = .chat
        case "referral":
            if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                // Handle referral code deep link
            }
        default:
            break
        }
    }
}
