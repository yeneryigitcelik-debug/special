import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: EliteSpacing.xl) {
                    // Header
                    VStack(spacing: EliteSpacing.md) {
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.eliteTextTertiary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.eliteSurface)
                                    .clipShape(Circle())
                            }
                        }

                        Text("Unlock\nÉLITE")
                            .font(EliteFont.displayXLarge())
                            .foregroundColor(.eliteTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("Elevate your experience")
                            .font(EliteFont.bodyLarge())
                            .foregroundColor(.eliteTextSecondary)
                    }

                    // Plan cards
                    VStack(spacing: EliteSpacing.md) {
                        ForEach(viewModel.plans) { plan in
                            planCard(plan)
                        }
                    }

                    // Subscribe button
                    VStack(spacing: EliteSpacing.md) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(EliteFont.bodySmall())
                                .foregroundColor(.eliteError)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }

                        EliteButton(
                            title: subscribeButtonTitle,
                            style: .primary,
                            isLoading: viewModel.isPurchasing
                        ) {
                            Task { await viewModel.purchase() }
                        }
                        .disabled(viewModel.selectedPlan?.tier == .free)

                        Button {
                            Task { await viewModel.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(EliteFont.bodySmall())
                                .foregroundColor(.eliteTextTertiary)
                                .underline()
                        }

                        Text("Auto-renewable subscription. Cancel anytime.\nTerms of Service and Privacy Policy apply.")
                            .font(EliteFont.caption())
                            .foregroundColor(.eliteTextTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.vertical, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.xxl)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var subscribeButtonTitle: String {
        guard let plan = viewModel.selectedPlan else { return "SELECT A PLAN" }
        if plan.tier == .free { return "CURRENT PLAN" }
        return "SUBSCRIBE — \(plan.price)\(plan.period)"
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let isSelected = viewModel.selectedPlan?.id == plan.id

        return Button {
            withAnimation(EliteAnimation.smooth) {
                viewModel.selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: EliteSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: EliteSpacing.xs) {
                        HStack(spacing: EliteSpacing.sm) {
                            Text(plan.name)
                                .font(EliteFont.headlineLarge())
                                .foregroundColor(.eliteTextPrimary)

                            if let badge = plan.badge {
                                Text(badge)
                                    .font(EliteFont.labelSmall())
                                    .foregroundColor(.eliteBackground)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.eliteAccent)
                                    .cornerRadius(4)
                            }
                        }

                        if !plan.price.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(plan.price)
                                    .font(EliteFont.displaySmall())
                                    .foregroundColor(.eliteAccent)
                                Text(plan.period)
                                    .font(EliteFont.bodySmall())
                                    .foregroundColor(.eliteTextTertiary)
                            }
                        }
                    }

                    Spacer()

                    Circle()
                        .strokeBorder(isSelected ? Color.eliteAccent : Color.eliteTextTertiary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(Color.eliteAccent)
                                .frame(width: 14, height: 14)
                                .opacity(isSelected ? 1 : 0)
                        )
                }

                VStack(alignment: .leading, spacing: EliteSpacing.xs) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: EliteSpacing.sm) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.eliteAccentMuted)

                            Text(feature)
                                .font(EliteFont.bodySmall())
                                .foregroundColor(.eliteTextSecondary)
                        }
                    }
                }
            }
            .padding(EliteSpacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: EliteRadius.large, style: .continuous)
                    .fill(isSelected ? Color.eliteSurfaceElevated : Color.eliteSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: EliteRadius.large, style: .continuous)
                    .strokeBorder(
                        isSelected
                        ? LinearGradient(colors: [.eliteAccent.opacity(0.6), .eliteAccentMuted.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.eliteDivider, Color.eliteDivider], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .shadow(color: isSelected ? .eliteAccent.opacity(0.12) : .clear, radius: 16, y: 4)
        }
    }
}

#Preview {
    PaywallView()
}
