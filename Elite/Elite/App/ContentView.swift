import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.selectedTab) {
                NavigationStack {
                    DiscoveryView()
                }
                .tag(AppRouter.Tab.discovery)

                NavigationStack {
                    ChatListView()
                }
                .tag(AppRouter.Tab.chat)

                NavigationStack {
                    ProfileDetailView(isOwnProfile: true)
                }
                .tag(AppRouter.Tab.profile)

                NavigationStack {
                    SettingsView()
                }
                .tag(AppRouter.Tab.settings)
            }
            .toolbar(.hidden, for: .tabBar)

            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Glass Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppRouter.Tab.allCases, id: \.rawValue) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.horizontal, EliteSpacing.sm)
        .padding(.top, EliteSpacing.sm + 6)
        .padding(.bottom, EliteSpacing.xl + 4)
        .background(
            ZStack {
                // Glass material
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .colorScheme(.dark)

                // Dark tint overlay
                Rectangle()
                    .fill(Color.eliteBackground.opacity(0.65))

                // Top edge highlight
                VStack {
                    LinearGradient(
                        colors: [Color.eliteAccent.opacity(0.06), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 1)
                    Spacer()
                }
            }
            .ignoresSafeArea()
        )
    }

    private func tabItem(for tab: AppRouter.Tab) -> some View {
        let isSelected = router.selectedTab == tab

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                router.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Active indicator glow
                    if isSelected {
                        Circle()
                            .fill(Color.eliteAccent.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "tabGlow", in: tabNamespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .symbolVariant(isSelected ? .fill : .none)
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .tracking(isSelected ? 0.5 : 0)
            }
            .foregroundColor(isSelected ? .eliteAccent : .eliteTextTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter())
        .environmentObject(NetworkMonitor.shared)
}
