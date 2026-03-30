import Foundation

final class ProfileService {
    private let api = APIClient.shared

    func fetchCurrentProfile() async throws -> User {
        let profile: User = try await api.request(.GET, path: "/api/v1/profile")
        return profile
    }

    func fetchProfile(id: UUID) async throws -> Profile {
        let profile: Profile = try await api.request(.GET, path: "/api/v1/profiles/\(id.uuidString)")
        return profile
    }

    func updateProfile(
        displayName: String?,
        bio: String?,
        title: String?,
        interestTags: [String]?,
        locationCity: String?
    ) async throws {
        let body = ProfileUpdateRequest(
            displayName: displayName,
            bio: bio,
            title: title,
            interestTags: interestTags,
            locationCity: locationCity
        )
        try await api.requestVoid(.PUT, path: "/api/v1/profile", body: body)
    }

    func updatePhotoURLs(_ urls: [String]) async throws {
        let body = ["photoUrls": urls]
        try await api.requestVoid(.PUT, path: "/api/v1/profile/photos", body: body)
    }

    func uploadPhoto(data: Data) async throws -> String {
        let response = try await api.uploadPhoto(data: data)
        return response.url
    }

    func deleteAccount() async throws {
        try await api.requestVoid(.DELETE, path: "/api/v1/profile")
        TokenManager.shared.clearTokens()
        await WebSocketManager.shared.disconnect()
    }
}

private struct ProfileUpdateRequest: Codable {
    let displayName: String?
    let bio: String?
    let title: String?
    let interestTags: [String]?
    let locationCity: String?
}
