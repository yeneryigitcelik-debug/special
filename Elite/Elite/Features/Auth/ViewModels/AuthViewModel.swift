import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var errorMessage: String?
    @Published var isAuthenticated = false

    enum ViewState {
        case idle, loading, loaded, error
    }

    private let authService = AuthService()

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        state = .loading
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                state = .error
                errorMessage = "Unable to process Apple Sign In credentials."
                return
            }

            do {
                _ = try await authService.signInWithApple(
                    idToken: tokenString,
                    fullName: credential.fullName
                )
                isAuthenticated = true
                state = .loaded
            } catch {
                state = .error
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                state = .idle
                return
            }
            state = .error
            errorMessage = "Sign in failed. Please try again."
        }
    }

    func validateReferralCode(_ code: String) async {
        state = .loading
        errorMessage = nil

        do {
            let isValid = try await authService.validateReferralCode(code)
            if isValid {
                guard let userId = TokenManager.shared.currentUserId else {
                    state = .error
                    errorMessage = "Please sign in first."
                    return
                }
                try await authService.redeemReferralCode(code, userId: userId)
                state = .loaded
            } else {
                state = .error
                errorMessage = "This invitation code is not valid."
            }
        } catch let error as APIError {
            state = .error
            errorMessage = error.errorDescription
        } catch {
            state = .error
            errorMessage = "Something went wrong. Please try again."
        }
    }

    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        state = .idle
    }
}
