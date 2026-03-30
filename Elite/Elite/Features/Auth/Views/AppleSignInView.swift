import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = AuthViewModel()
    @State private var navigateToReferral = false

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: EliteSpacing.xxl) {
                Spacer()

                VStack(spacing: EliteSpacing.md) {
                    Text("ÉLITE")
                        .font(EliteFont.displayLarge())
                        .tracking(8)
                        .foregroundColor(.eliteAccent)

                    Text("Sign in to continue")
                        .font(EliteFont.bodyLarge())
                        .foregroundColor(.eliteTextSecondary)
                }

                Spacer()

                VStack(spacing: EliteSpacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await viewModel.handleAppleSignIn(result: result)
                            if viewModel.isAuthenticated {
                                navigateToReferral = true
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(EliteRadius.medium)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(EliteFont.bodySmall())
                            .foregroundColor(.eliteError)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Text("By continuing, you agree to our Terms of Service\nand Privacy Policy")
                        .font(EliteFont.caption())
                        .foregroundColor(.eliteTextTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.xxl)
            }
        }
        .hideNavigationBar()
        .navigationDestination(isPresented: $navigateToReferral) {
            ReferralCodeView()
        }
        .overlay {
            if viewModel.state == .loading {
                Color.eliteBackground.opacity(0.6)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.eliteAccent))
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppleSignInView()
            .environmentObject(AppRouter())
    }
}
