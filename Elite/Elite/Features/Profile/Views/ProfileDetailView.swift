import SwiftUI
import NukeUI

struct ProfileDetailView: View {
    var profile: Profile? = nil
    var isOwnProfile: Bool = false

    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var headerVisible = false

    private var displayProfile: Profile? {
        if let profile { return profile }
        guard let user = viewModel.user else { return nil }
        return Profile(
            id: user.id,
            displayName: user.displayName,
            birthdate: user.birthdate,
            gender: user.gender,
            bio: user.bio,
            title: user.title,
            locationCity: user.locationCity,
            photoURLs: user.photoURLs,
            interestTags: user.interestTags,
            isVerified: user.isVerified,
            subscriptionTier: user.subscriptionTier
        )
    }

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            if let profile = displayProfile {
                profileContent(profile)
            } else if viewModel.state == .loading {
                ProgressView().tint(.eliteAccent)
            }

            // Sticky header on scroll
            if headerVisible, let profile = displayProfile {
                VStack {
                    stickyHeader(profile)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .hideNavigationBar()
        .task {
            if isOwnProfile {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ProfileEditView(viewModel: viewModel)
        }
    }

    private func profileContent(_ profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero photo
                GeometryReader { geo in
                    let minY = geo.frame(in: .global).minY
                    let isScrolledPast = minY < -200

                    if let url = profile.primaryPhotoURL, let imageUrl = URL(string: url) {
                        LazyImage(url: imageUrl) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: max(geo.size.height + max(minY, 0), geo.size.height))
                                    .offset(y: min(minY, 0) * 0.3)
                                    .clipped()
                            } else {
                                Color.eliteSurfaceElevated
                            }
                        }
                        .onChange(of: isScrolledPast) { _, newVal in
                            withAnimation(EliteAnimation.smooth) {
                                headerVisible = newVal
                            }
                        }
                    } else {
                        Color.eliteSurfaceElevated
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.eliteTextTertiary)
                            )
                    }
                }
                .frame(height: 480)
                .overlay(alignment: .bottom) {
                    GradientOverlay(style: .bottom)
                        .frame(height: 200)
                }

                // Profile info
                VStack(alignment: .leading, spacing: EliteSpacing.lg) {
                    // Name & age
                    HStack(alignment: .firstTextBaseline, spacing: EliteSpacing.sm) {
                        Text(profile.displayName)
                            .font(EliteFont.displayMedium())
                            .foregroundColor(.eliteTextPrimary)

                        Text("\(profile.age)")
                            .font(EliteFont.displaySmall())
                            .foregroundColor(.eliteTextSecondary)

                        if profile.isVerified {
                            VerifiedBadge(size: 22)
                        }

                        Spacer()

                        if isOwnProfile {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showEditSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.eliteAccent)
                                    .frame(width: 44, height: 44)
                                    .background(Color.eliteSurface)
                                    .clipShape(Circle())
                            }
                        }
                    }

                    // Title & location
                    if let titleText = profile.title, !titleText.isEmpty {
                        Text(titleText)
                            .font(EliteFont.headlineMedium())
                            .foregroundColor(.eliteTextSecondary)
                    }

                    if let city = profile.locationCity, !city.isEmpty {
                        HStack(spacing: EliteSpacing.xs) {
                            Image(systemName: "mappin")
                                .font(.system(size: 13))
                            Text(city)
                                .font(EliteFont.bodyMedium())
                        }
                        .foregroundColor(.eliteTextTertiary)
                    }

                    // Bio
                    if let bio = profile.bio, !bio.isEmpty {
                        Rectangle()
                            .fill(Color.eliteDivider)
                            .frame(height: 0.5)

                        Text(bio)
                            .font(EliteFont.bodyLarge())
                            .foregroundColor(.eliteTextPrimary)
                            .lineSpacing(6)
                    }

                    // Interest tags
                    if !profile.interestTags.isEmpty {
                        Rectangle()
                            .fill(Color.eliteDivider)
                            .frame(height: 0.5)

                        VStack(alignment: .leading, spacing: EliteSpacing.sm) {
                            Text("Interests")
                                .font(EliteFont.labelMedium())
                                .foregroundColor(.eliteTextTertiary)

                            TagChipFlow(tags: profile.interestTags)
                        }
                    }

                    // Photo gallery
                    if profile.photoURLs.count > 1 {
                        Rectangle()
                            .fill(Color.eliteDivider)
                            .frame(height: 0.5)

                        PhotoGridView(photoURLs: Array(profile.photoURLs.dropFirst()))
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.top, -40)
                .padding(.bottom, 120)
            }
        }
    }

    private func stickyHeader(_ profile: Profile) -> some View {
        HStack(spacing: EliteSpacing.sm) {
            AvatarView(imageURL: profile.primaryPhotoURL, size: 32)

            Text("\(profile.displayName), \(profile.age)")
                .font(EliteFont.headlineMedium())
                .foregroundColor(.eliteTextPrimary)

            if profile.isVerified {
                VerifiedBadge(size: 14)
            }

            Spacer()
        }
        .padding(.horizontal, EliteSpacing.lg)
        .padding(.vertical, EliteSpacing.sm)
        .background(.ultraThinMaterial)
        .colorScheme(.dark)
        .background(Color.eliteBackground.opacity(0.8))
    }
}
