import SwiftUI

struct VerifiedBadge: View {
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [.eliteAccent, .eliteAccentMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    HStack {
        Text("Alexandra")
            .font(EliteFont.headlineLarge())
            .foregroundColor(.eliteTextPrimary)
        VerifiedBadge()
    }
    .padding()
    .background(Color.eliteBackground)
}
