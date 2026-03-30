import Foundation

final class MatchService {
    private let api = APIClient.shared

    func fetchDiscoveryProfiles() async throws -> [Profile] {
        let profiles: [Profile] = try await api.request(
            .GET,
            path: "/api/v1/discovery/profiles",
            queryItems: [URLQueryItem(name: "limit", value: "50")]
        )
        return profiles
    }

    func swipe(on userId: UUID, action: SwipeAction) async throws -> Match? {
        let body = SwipeRequest(swipedId: userId, action: action)
        let response: SwipeResponse = try await api.request(.POST, path: "/api/v1/swipes", body: body)
        return response.match
    }
}

private struct SwipeRequest: Codable {
    let swipedId: UUID
    let action: SwipeAction
}

private struct SwipeResponse: Codable {
    let match: Match?
}
