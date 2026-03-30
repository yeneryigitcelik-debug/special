import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var router: AppRouter
    @State private var currentPage = 0
    @State private var navigateToReferral = false
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Curated\nConnections",
            subtitle: "Every profile is hand-selected.\nQuality over quantity, always.",
            icon: "sparkles",
            gradientColors: [Color(hex: "#2A2520"), Color(hex: "#1A1814")]
        ),
        OnboardingPage(
            title: "Invited\nOnly",
            subtitle: "Join through a personal invitation\nfrom an existing member.",
            icon: "envelope.badge",
            gradientColors: [Color(hex: "#1E2420"), Color(hex: "#1A1814")]
        ),
        OnboardingPage(
            title: "Your Inner\nCircle",
            subtitle: "Where meaningful connections\nbegin with intention.",
            icon: "person.2",
            gradientColors: [Color(hex: "#242020"), Color(hex: "#1A1814")]
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background gradient
                LinearGradient(
                    colors: pages[currentPage].gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: currentPage)

                // Subtle ambient particles
                ambientParticles

                VStack(spacing: 0) {
                    // Logo header
                    HStack {
                        Text("ÉLITE")
                            .font(EliteFont.labelMedium())
                            .tracking(4)
                            .foregroundColor(.eliteAccentMuted.opacity(0.5))
                        Spacer()
                    }
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.top, EliteSpacing.md)

                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            pageContent(pages[index], index: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    VStack(spacing: EliteSpacing.xl) {
                        // Elegant line indicators
                        pageIndicator

                        if currentPage == pages.count - 1 {
                            enterButton
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        } else {
                            // Skip hint
                            Button {
                                withAnimation(EliteAnimation.medium) {
                                    currentPage = pages.count - 1
                                }
                            } label: {
                                Text("Skip")
                                    .font(EliteFont.labelMedium())
                                    .foregroundColor(.eliteTextTertiary)
                            }
                            .frame(height: 52)
                            .transition(.opacity)
                        }
                    }
                    .animation(EliteAnimation.medium, value: currentPage)
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.bottom, EliteSpacing.xxl)
                }
            }
            .navigationDestination(isPresented: $navigateToReferral) {
                AppleSignInView()
            }
        }
    }

    // MARK: - Page Content
    private func pageContent(_ page: OnboardingPage, index: Int) -> some View {
        VStack(spacing: EliteSpacing.xxl) {
            Spacer()

            // Floating icon with glow
            ZStack {
                // Glow ring
                Circle()
                    .stroke(Color.eliteAccent.opacity(0.08), lineWidth: 1)
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(Color.eliteAccent.opacity(0.04), lineWidth: 1)
                    .frame(width: 180, height: 180)

                // Soft glow behind icon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.eliteAccent.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .thin))
                    .foregroundColor(.eliteAccent.opacity(0.7))
            }
            .offset(y: appeared ? 0 : 20)

            VStack(spacing: EliteSpacing.md) {
                Text(page.title)
                    .font(EliteFont.displayMedium())
                    .foregroundColor(.eliteTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text(page.subtitle)
                    .font(EliteFont.bodyLarge())
                    .foregroundColor(.eliteTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, EliteSpacing.xl)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Enter Button
    private var enterButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            navigateToReferral = true
        } label: {
            HStack(spacing: EliteSpacing.sm) {
                Text("ENTER ÉLITE")
                    .font(EliteFont.labelLarge())
                    .tracking(2)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.eliteBackground)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.eliteAccent, .eliteAccentMuted],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(EliteRadius.medium)
            .shadow(color: .eliteAccent.opacity(0.25), radius: 20, y: 8)
        }
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: EliteSpacing.sm) {
            ForEach(0..<pages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index == currentPage ? Color.eliteAccent : Color.eliteTextTertiary.opacity(0.3))
                    .frame(width: index == currentPage ? 28 : 12, height: 2)
                    .animation(.easeInOut(duration: 0.35), value: currentPage)
            }
        }
    }

    // MARK: - Ambient Particles
    private var ambientParticles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<12 {
                    let phase = Double(i) * 0.5
                    let x = size.width * (0.1 + 0.8 * CGFloat(i) / 12.0)
                        + sin(time * 0.3 + phase) * 15
                    let y = size.height * (0.2 + 0.6 * CGFloat(i % 4) / 4.0)
                        + cos(time * 0.25 + phase) * 20
                    let opacity = 0.06 + 0.08 * sin(time * 0.5 + phase)
                    let dotSize: CGFloat = CGFloat(2 + i % 3)

                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                        with: .color(.eliteAccent)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
}

#Preview {
    OnboardingView()
        .environmentObject(AppRouter())
}
