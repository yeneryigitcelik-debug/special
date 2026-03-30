import SwiftUI

struct CardStackView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    var onProfileTap: ((Profile) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if viewModel.profiles.isEmpty && viewModel.state == .loaded {
                    emptyState
                } else {
                    ForEach(Array(viewModel.profiles.prefix(3).enumerated().reversed()), id: \.element.id) { index, profile in
                        let isTop = index == 0
                        cardView(for: profile, at: index, isTop: isTop, in: geo)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardView(for profile: Profile, at index: Int, isTop: Bool, in geo: GeometryProxy) -> some View {
        let scale = 1.0 - CGFloat(index) * 0.04
        let yOffset = CGFloat(index) * -12

        return ProfileCardView(profile: profile) {
            onProfileTap?(profile)
        }
        .frame(
            width: geo.size.width - EliteSpacing.lg * 2,
            height: geo.size.height - EliteSpacing.xxl
        )
        .scaleEffect(isTop ? 1.0 : scale)
        .offset(y: isTop ? 0 : yOffset)
        .offset(x: isTop ? viewModel.dragOffset.width : 0, y: isTop ? viewModel.dragOffset.height : 0)
        .rotationEffect(isTop ? .degrees(Double(viewModel.dragOffset.width) / 25) : .zero)
        .gesture(isTop ? dragGesture(for: profile) : nil)
        .animation(EliteAnimation.spring, value: viewModel.dragOffset)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .move(edge: viewModel.dragOffset.width > 0 ? .trailing : .leading)
                .combined(with: .opacity)
        ))
    }

    private func dragGesture(for profile: Profile) -> some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.dragOffset = value.translation
            }
            .onEnded { value in
                let width = value.translation.width
                let height = value.translation.height
                let threshold: CGFloat = 120

                if width > threshold {
                    // Like
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    swipeAway(profile: profile, action: .like, direction: .trailing)
                } else if width < -threshold {
                    // Pass
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    swipeAway(profile: profile, action: .pass, direction: .leading)
                } else if height < -threshold {
                    // Superlike
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    swipeAway(profile: profile, action: .superlike, direction: .top)
                } else {
                    withAnimation(EliteAnimation.spring) {
                        viewModel.dragOffset = .zero
                    }
                }
            }
    }

    private func swipeAway(profile: Profile, action: SwipeAction, direction: Edge) {
        let offScreenX: CGFloat = direction == .trailing ? 500 : direction == .leading ? -500 : 0
        let offScreenY: CGFloat = direction == .top ? -800 : 0

        withAnimation(EliteAnimation.medium) {
            viewModel.dragOffset = CGSize(width: offScreenX, height: offScreenY)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.dragOffset = .zero
            Task {
                await viewModel.swipe(on: profile, action: action)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: EliteSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.eliteTextTertiary)

            VStack(spacing: EliteSpacing.sm) {
                Text("No More Profiles")
                    .font(EliteFont.headlineLarge())
                    .foregroundColor(.eliteTextPrimary)

                Text("Expand your preferences to\ndiscover more connections")
                    .font(EliteFont.bodyMedium())
                    .foregroundColor(.eliteTextSecondary)
                    .multilineTextAlignment(.center)
            }

            EliteButton(title: "REFRESH", style: .secondary) {
                Task { await viewModel.loadProfiles() }
            }
            .frame(width: 200)
        }
    }
}
