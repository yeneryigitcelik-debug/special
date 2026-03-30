import SwiftUI

struct EliteCard<Content: View>: View {
    var padding: CGFloat = EliteSpacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .background(Color.eliteSurface)
        .cornerRadius(EliteRadius.large)
        .eliteShadow(EliteShadow.subtle)
    }
}

#Preview {
    EliteCard {
        Text("Card Content")
            .font(EliteFont.bodyLarge())
            .foregroundColor(.eliteTextPrimary)
    }
    .padding(24)
    .background(Color.eliteBackground)
}
