import SwiftUI
import NukeUI

struct AvatarView: View {
    let imageURL: String?
    var size: CGFloat = 48
    var showOnlineIndicator: Bool = false
    var isOnline: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let url = imageURL, let imageUrl = URL(string: url) {
                LazyImage(url: imageUrl) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.error != nil {
                        placeholderView
                    } else {
                        shimmerView
                    }
                }
                .processors([.resize(size: CGSize(width: size * 2, height: size * 2))])
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholderView
            }

            if showOnlineIndicator && isOnline {
                Circle()
                    .fill(Color.eliteSuccess)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.eliteBackground, lineWidth: 2)
                    )
                    .offset(x: -2, y: -2)
            }
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(Color.eliteSurfaceElevated)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.eliteTextTertiary)
            )
    }

    private var shimmerView: some View {
        Circle()
            .fill(Color.eliteSurface)
            .frame(width: size, height: size)
            .modifier(ShimmerModifier())
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(imageURL: nil, size: 48)
        AvatarView(imageURL: nil, size: 64, showOnlineIndicator: true, isOnline: true)
        AvatarView(imageURL: nil, size: 80)
    }
    .padding()
    .background(Color.eliteBackground)
}
