import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: EliteSpacing.lg) {
                    header

                    // Account
                    settingsSection("Account") {
                        settingsRow(icon: "person", title: "Edit Profile") {
                            // Navigate to edit
                        }
                        settingsRow(icon: "crown", title: "Subscription", badge: "FREE") {
                            showPaywall = true
                        }
                    }

                    // Preferences
                    settingsSection("Preferences") {
                        settingsRow(icon: "slider.horizontal.3", title: "Discovery Settings") {}
                        settingsRow(icon: "bell", title: "Notifications") {}
                    }

                    // Privacy
                    settingsSection("Privacy & Safety") {
                        settingsRow(icon: "hand.raised", title: "Blocked Users") {}
                        settingsRow(icon: "trash", title: "Delete Account", isDestructive: true) {
                            showDeleteConfirmation = true
                        }
                    }

                    // About
                    settingsSection("About") {
                        settingsRow(icon: "doc.text", title: "Terms of Service") {}
                        settingsRow(icon: "lock.shield", title: "Privacy Policy") {}
                        settingsRow(icon: "info.circle", title: "Licenses") {}
                    }

                    // Sign out
                    EliteButton(title: "SIGN OUT", style: .destructive) {
                        Task { await router.signOut() }
                    }
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.top, EliteSpacing.md)

                    // Version
                    Text("ÉLITE v1.0.0")
                        .font(EliteFont.caption())
                        .foregroundColor(.eliteTextTertiary)
                        .padding(.top, EliteSpacing.sm)
                        .padding(.bottom, 120)
                }
            }
        }
        .hideNavigationBar()
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await ProfileService().deleteAccount()
                    await router.signOut()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(EliteFont.displaySmall())
                .foregroundColor(.eliteTextPrimary)
            Spacer()
        }
        .padding(.horizontal, EliteSpacing.lg)
        .padding(.top, EliteSpacing.sm)
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(EliteFont.labelSmall())
                .foregroundColor(.eliteTextTertiary)
                .tracking(1.5)
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.sm)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.eliteSurface)
            .cornerRadius(EliteRadius.large)
            .padding(.horizontal, EliteSpacing.md)
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        badge: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: EliteSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .eliteError : .eliteTextSecondary)
                    .frame(width: 24)

                Text(title)
                    .font(EliteFont.bodyLarge())
                    .foregroundColor(isDestructive ? .eliteError : .eliteTextPrimary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(EliteFont.labelSmall())
                        .foregroundColor(.eliteAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.eliteAccent.opacity(0.15))
                        .cornerRadius(4)
                }

                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.eliteTextTertiary)
                }
            }
            .padding(.horizontal, EliteSpacing.md)
            .padding(.vertical, EliteSpacing.sm + 4)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppRouter())
}
