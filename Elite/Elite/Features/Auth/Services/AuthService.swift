import Foundation

final class AuthService {
    private let api = APIClient.shared
    private let tokenManager = TokenManager.shared

    func signInWithApple(idToken: String, fullName: PersonNameComponents?) async throws -> User {
        var displayName = "Member"
        if let name = fullName {
            let parts = [name.givenName, name.familyName].compactMap { $0 }
            if !parts.isEmpty {
                displayName = parts.joined(separator: " ")
            }
        }

        let body = AppleSignInRequest(idToken: idToken, displayName: displayName)
        let response: AuthResponse = try await api.request(.POST, path: "/api/v1/auth/apple", body: body, requiresAuth: false)

        tokenManager.accessToken = response.accessToken
        tokenManager.refreshToken = response.refreshToken

        return response.user
    }

    func validateReferralCode(_ code: String) async throws -> Bool {
        let body = ["code": code.uppercased()]
        do {
            let response: ReferralValidateResponse = try await api.request(.POST, path: "/api/v1/referral/validate", body: body)
            return response.valid
        } catch {
            return false
        }
    }

    func redeemReferralCode(_ code: String, userId: UUID) async throws {
        let body = ["code": code.uppercased()]
        try await api.requestVoid(.POST, path: "/api/v1/referral/redeem", body: body)
    }

    func generateReferralCode(for userId: UUID) async throws -> String {
        let response: ReferralGenerateResponse = try await api.request(.POST, path: "/api/v1/referral/generate")
        return response.code
    }

    func signOut() async {
        try? await api.requestVoid(.POST, path: "/api/v1/auth/logout")
        tokenManager.clearTokens()
        await WebSocketManager.shared.disconnect()
    }

    func refreshSession() async throws -> User {
        let user: User = try await api.request(.GET, path: "/api/v1/profile")
        return user
    }
}

// MARK: - Request/Response Types

private struct AppleSignInRequest: Codable {
    let idToken: String
    let displayName: String
}

struct ReferralValidateResponse: Codable {
    let valid: Bool
}

struct ReferralGenerateResponse: Codable {
    let code: String
}
