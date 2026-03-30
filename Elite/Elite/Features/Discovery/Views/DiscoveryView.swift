import SwiftUI

struct DiscoveryView: View {
    @StateObject private var viewModel = DiscoveryViewModel()
    @State private var selectedProfile: Profile?
    @State private var showProfileDetail = false

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.bottom, EliteSpacing.sm)

                CardStackView(viewModel: viewModel) { profile in
                    selectedProfile = profile
                    showProfileDetail = true
                }
                .padding(.horizontal, EliteSpacing.sm)

                actionButtons
                    .padding(.horizontal, EliteSpacing.xxl)
                    .padding(.vertical, EliteSpacing.md)
            }
        }
        .hideNavigationBar()
        .overlay {
            if let match = viewModel.newMatch {
                MatchView(match: match) {
                    viewModel.newMatch = nil
                }
            }
        }
        .sheet(isPresented: $showProfileDetail) {
            if let profile = selectedProfile {
                ProfileDetailView(profile: profile)
            }
        }
        .task {
            await viewModel.loadProfiles()
        }
        .refreshable {
            await viewModel.loadProfiles()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("ÉLITE")
                .font(EliteFont.displaySmall())
                .tracking(6)
                .foregroundColor(.eliteAccent)

            Spacer()

            Button {
                // Filter action
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.eliteTextSecondary)
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: EliteSpacing.xl) {
            actionButton(icon: "xmark", color: .eliteError, size: 52) {
                guard let profile = viewModel.profiles.first else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await viewModel.swipe(on: profile, action: .pass) }
            }

            actionButton(icon: "star.fill", color: .eliteAccent, size: 44) {
                guard let profile = viewModel.profiles.first else { return }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                Task { await viewModel.swipe(on: profile, action: .superlike) }
            }

            actionButton(icon: "heart.fill", color: .eliteSuccess, size: 52) {
                guard let profile = viewModel.profiles.first else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await viewModel.swipe(on: profile, action: .like) }
            }
        }
    }

    private func actionButton(icon: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(color.opacity(0.08), lineWidth: 1)
                    .frame(width: size + 8, height: size + 8)

                Circle()
                    .fill(Color.eliteSurface)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(color.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.15), radius: 12, y: 4)

                Image(systemName: icon)
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    DiscoveryView()
}
