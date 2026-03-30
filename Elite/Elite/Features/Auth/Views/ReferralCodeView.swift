import SwiftUI

struct ReferralCodeView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var codeCharacters: [String] = Array(repeating: "", count: 6).map { $0 }
    @State private var shake = false
    @State private var navigateToWaitlist = false

    private var fullCode: String {
        codeCharacters.joined()
    }

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: EliteSpacing.xxl) {
                Spacer()

                VStack(spacing: EliteSpacing.md) {
                    Text("Enter Your\nInvitation")
                        .font(EliteFont.displayMedium())
                        .foregroundColor(.eliteTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Enter the 6-character code from your invitation")
                        .font(EliteFont.bodyMedium())
                        .foregroundColor(.eliteTextSecondary)
                        .multilineTextAlignment(.center)
                }

                codeInputField
                    .offset(x: shake ? -10 : 0)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(EliteFont.bodySmall())
                        .foregroundColor(.eliteError)
                        .transition(.opacity)
                }

                Spacer()

                VStack(spacing: EliteSpacing.md) {
                    EliteButton(
                        title: "VALIDATE",
                        style: .primary,
                        isLoading: viewModel.state == .loading
                    ) {
                        Task { await validateCode() }
                    }

                    EliteButton(title: "APPLY TO JOIN", style: .secondary) {
                        navigateToWaitlist = true
                    }

                    Button {
                        navigateToWaitlist = true
                    } label: {
                        Text("Don't have a code?")
                            .font(EliteFont.bodySmall())
                            .foregroundColor(.eliteTextTertiary)
                            .underline()
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.xxl)
            }
        }
        .hideNavigationBar()
        .navigationDestination(isPresented: $navigateToWaitlist) {
            WaitlistView()
        }
        .onAppear {
            isFieldFocused = true
        }
    }

    private var codeInputField: some View {
        HStack(spacing: EliteSpacing.sm) {
            ForEach(0..<6, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: EliteRadius.small)
                        .fill(Color.eliteSurface)
                        .frame(width: 48, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: EliteRadius.small)
                                .strokeBorder(
                                    characterBorderColor(index: index),
                                    lineWidth: 1
                                )
                        )

                    Text(codeCharacters[index])
                        .font(EliteFont.displaySmall())
                        .foregroundColor(.eliteTextPrimary)
                }
            }
        }
        .background(
            TextField("", text: hiddenTextFieldBinding)
                .focused($isFieldFocused)
                .textInputAutocapitalization(.characters)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .opacity(0)
                .frame(width: 1, height: 1)
        )
        .onTapGesture {
            isFieldFocused = true
        }
    }

    private var hiddenTextFieldBinding: Binding<String> {
        Binding(
            get: { fullCode },
            set: { newValue in
                viewModel.errorMessage = nil
                let filtered = String(newValue.uppercased().prefix(6).filter { $0.isLetter || $0.isNumber })
                for i in 0..<6 {
                    codeCharacters[i] = i < filtered.count ? String(filtered[filtered.index(filtered.startIndex, offsetBy: i)]) : ""
                }
            }
        )
    }

    private func characterBorderColor(index: Int) -> Color {
        if !codeCharacters[index].isEmpty {
            return .eliteAccent.opacity(0.5)
        } else if index == fullCode.count {
            return .eliteAccent.opacity(0.3)
        }
        return .eliteDivider
    }

    private func validateCode() async {
        guard fullCode.count == 6 else {
            shakeField()
            return
        }

        await viewModel.validateReferralCode(fullCode)

        if viewModel.state == .error {
            shakeField()
        } else if viewModel.state == .loaded {
            isFieldFocused = false
            router.authState = .authenticated
        }
    }

    private func shakeField() {
        withAnimation(.default.repeatCount(4, autoreverses: true).speed(6)) {
            shake = true
        }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shake = false
        }
    }
}

#Preview {
    NavigationStack {
        ReferralCodeView()
            .environmentObject(AppRouter())
    }
}
