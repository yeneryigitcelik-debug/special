import SwiftUI

struct SubscriptionBadge: View {
    let tier: User.SubscriptionTier

    var body: some View {
        if tier != .free {
            HStack(spacing: EliteSpacing.xs) {
                Image(systemName: tier == .black ? "crown.fill" : "star.fill")
                    .font(.system(size: 10))

                Text(tierLabel)
                    .font(EliteFont.labelSmall())
                    .tracking(0.8)
            }
            .foregroundColor(tier == .black ? .eliteBackground : .eliteAccent)
            .padding(.horizontal, EliteSpacing.sm)
            .padding(.vertical, EliteSpacing.xs)
            .background(tier == .black ? Color.eliteAccent : Color.eliteAccent.opacity(0.15))
            .cornerRadius(6)
        }
    }

    private var tierLabel: String {
        switch tier {
        case .free: return ""
        case .plus: return "ÉLITE+"
        case .black: return "BLACK"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SubscriptionBadge(tier: .plus)
        SubscriptionBadge(tier: .black)
    }
    .padding()
    .background(Color.eliteBackground)
}
