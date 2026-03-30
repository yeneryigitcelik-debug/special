import SwiftUI
import NukeUI

struct ProfileCardView: View {
    let profile: Profile
    var onTap: (() -> Void)? = nil

    @State private var offset: CGSize = .zero
    @State private var photoIndex: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Photo with tap zones for multi-photo
                photoLayer(size: geo.size)

                // Cinematic gradient overlay
                VStack(spacing: 0) {
                    // Top subtle vignette
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)

                    Spacer()

                    // Bottom info gradient — deeper, more cinematic
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.15), .black.opacity(0.55), .black.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.55)
                }
                .allowsHitTesting(false)

                // Swipe feedback overlays
                swipeOverlay

                // Profile info with glass effect
                profileInfoOverlay
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.bottom, EliteSpacing.lg)

                // Photo pagination dots (if multiple photos)
                if profile.photoURLs.count > 1 {
                    photoPagination
                        .padding(.top, EliteSpacing.xxl)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: EliteRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EliteRadius.xl, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.eliteAccent.opacity(borderGlowOpacity),
                                .clear,
                                Color.eliteAccent.opacity(borderGlowOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        }
        .onTapGesture { onTap?() }
    }

    // MARK: - Photo Layer
    private func photoLayer(size: CGSize) -> some View {
        let urlString = photoIndex < profile.photoURLs.count
            ? profile.photoURLs[photoIndex]
            : profile.primaryPhotoURL

        return Group {
            if let urlStr = urlString, let url = URL(string: urlStr) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    } else if state.error != nil {
                        placeholderImage(size: size)
                    } else {
                        placeholderImage(size: size)
                            .overlay(
                                ProgressView()
                                    .tint(.eliteAccent.opacity(0.5))
                            )
                    }
                }
            } else {
                placeholderImage(size: size)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                        let tapX = value.location.x
                        if tapX < size.width * 0.3 && photoIndex > 0 {
                            withAnimation(EliteAnimation.smooth) { photoIndex -= 1 }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } else if tapX > size.width * 0.7 && photoIndex < profile.photoURLs.count - 1 {
                            withAnimation(EliteAnimation.smooth) { photoIndex += 1 }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
        )
    }

    // MARK: - Photo Pagination
    private var photoPagination: some View {
        HStack(spacing: 4) {
            ForEach(0..<profile.photoURLs.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(index == photoIndex ? Color.white : Color.white.opacity(0.35))
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, EliteSpacing.md)
    }

    // MARK: - Swipe Overlay
    private var swipeOverlay: some View {
        ZStack {
            // Like glow
            RoundedRectangle(cornerRadius: EliteRadius.xl, style: .continuous)
                .fill(Color.eliteSuccess.opacity(0.15))
                .overlay(
                    VStack {
                        Text("LIKE")
                            .font(EliteFont.displayLarge())
                            .tracking(6)
                            .foregroundColor(.eliteSuccess)
                            .rotationEffect(.degrees(-15))
                            .padding(.top, 80)
                            .padding(.leading, 30)
                        Spacer()
                    }
                    , alignment: .topLeading
                )
                .opacity(likeOpacity)

            // Pass glow
            RoundedRectangle(cornerRadius: EliteRadius.xl, style: .continuous)
                .fill(Color.eliteError.opacity(0.15))
                .overlay(
                    VStack {
                        Text("PASS")
                            .font(EliteFont.displayLarge())
                            .tracking(6)
                            .foregroundColor(.eliteError)
                            .rotationEffect(.degrees(15))
                            .padding(.top, 80)
                            .padding(.trailing, 30)
                        Spacer()
                    }
                    , alignment: .topTrailing
                )
                .opacity(passOpacity)

            // Superlike glow
            RoundedRectangle(cornerRadius: EliteRadius.xl, style: .continuous)
                .fill(Color.eliteAccent.opacity(0.15))
                .overlay(
                    Text("SUPERLIKE")
                        .font(EliteFont.displayMedium())
                        .tracking(6)
                        .foregroundColor(.eliteAccent)
                )
                .opacity(superlikeOpacity)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Profile Info
    private var profileInfoOverlay: some View {
        VStack(alignment: .leading, spacing: EliteSpacing.sm) {
            Spacer()

            // Name row
            HStack(alignment: .firstTextBaseline, spacing: EliteSpacing.sm) {
                Text(profile.displayName)
                    .font(EliteFont.displayMedium())
                    .foregroundColor(.eliteTextPrimary)

                Text("\(profile.age)")
                    .font(EliteFont.displaySmall())
                    .foregroundColor(.eliteTextPrimary.opacity(0.7))

                if profile.isVerified {
                    VerifiedBadge(size: 20)
                }
            }

            // Title
            if let title = profile.title, !title.isEmpty {
                Text(title)
                    .font(EliteFont.headlineMedium())
                    .foregroundColor(.eliteTextSecondary)
            }

            // Location
            if let city = profile.locationCity, !city.isEmpty {
                HStack(spacing: EliteSpacing.xs) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11, weight: .medium))
                    Text(city)
                        .font(EliteFont.bodyMedium())
                }
                .foregroundColor(.eliteTextTertiary)
            }

            // Interest tags with glass style
            if !profile.interestTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(profile.interestTags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(EliteFont.labelSmall())
                                .foregroundColor(.eliteTextPrimary.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial.opacity(0.6))
                                .colorScheme(.dark)
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.top, EliteSpacing.xs)
            }
        }
    }

    // MARK: - Helpers
    private func placeholderImage(size: CGSize) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.eliteSurfaceElevated, Color.eliteSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size.width, height: size.height)
            .overlay(
                VStack(spacing: EliteSpacing.sm) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.eliteTextTertiary.opacity(0.5))
                }
            )
    }

    var likeOpacity: Double {
        max(0, min(1, Double(offset.width) / 100))
    }

    var passOpacity: Double {
        max(0, min(1, Double(-offset.width) / 100))
    }

    var superlikeOpacity: Double {
        max(0, min(1, Double(-offset.height) / 100))
    }

    private var borderGlowOpacity: Double {
        let maxSwipe = max(abs(offset.width), abs(offset.height))
        return min(0.4, maxSwipe / 200)
    }

    func updateOffset(_ offset: CGSize) {
        self.offset = offset
    }
}
