import SwiftUI

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var profiles: [Profile] = []
    @Published var dragOffset: CGSize = .zero
    @Published var newMatch: Match?
    @Published var errorMessage: String?

    enum ViewState {
        case idle, loading, loaded, error
    }

    private let matchService = MatchService()

    func loadProfiles() async {
        state = .loading
        do {
            profiles = try await matchService.fetchDiscoveryProfiles()
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    func swipe(on profile: Profile, action: SwipeAction) async {
        withAnimation(EliteAnimation.medium) {
            profiles.removeAll { $0.id == profile.id }
        }

        do {
            let match = try await matchService.swipe(on: profile.id, action: action)
            if let match {
                var matchWithProfile = match
                matchWithProfile.otherProfile = profile
                withAnimation(EliteAnimation.slow) {
                    newMatch = matchWithProfile
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        // Load more if running low
        if profiles.count < 3 {
            await loadMore()
        }
    }

    private func loadMore() async {
        do {
            let newProfiles = try await matchService.fetchDiscoveryProfiles()
            let existingIds = Set(profiles.map(\.id))
            let filtered = newProfiles.filter { !existingIds.contains($0.id) }
            profiles.append(contentsOf: filtered)
        } catch {
            // Silently fail on background load
        }
    }
}
