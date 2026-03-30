import SwiftUI

struct MatchView: View {
    let match: Match
    let onDismiss: () -> Void

    @State private var phase = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var avatarsVisible = false
    @State private var titleVisible = false
    @State private var buttonsVisible = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var particles: [MatchParticle] = []

    var body: some View {
        ZStack {
            // Deep blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .colorScheme(.dark)
                .overlay(Color.eliteBackground.opacity(0.75))
                .ignoresSafeArea()

            // Radial accent glow
            RadialGradient(
                colors: [
                    Color.eliteAccent.opacity(0.08),
                    Color.eliteAccent.opacity(0.03),
                    .clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 250
            )
            .scaleEffect(pulseScale)
            .ignoresSafeArea()

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .blur(radius: p.size > 4 ? 1 : 0)
                    .position(p.position)
                    .opacity(p.opacity)
            }

            VStack(spacing: EliteSpacing.xxl) {
                Spacer()

                // Ring + avatars cluster
                ZStack {
                    // Pulsing rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.eliteAccent.opacity(0.06 - Double(i) * 0.015), lineWidth: 0.5)
                            .frame(width: 200 + CGFloat(i) * 50, height: 200 + CGFloat(i) * 50)
                            .scaleEffect(ringScale + CGFloat(i) * 0.05)
                            .opacity(ringOpacity)
                    }

                    // Avatars
                    HStack(spacing: EliteSpacing.xl + 8) {
                        matchAvatar(url: match.otherProfile?.primaryPhotoURL)
                            .offset(x: avatarsVisible ? 0 : -40)
                            .opacity(avatarsVisible ? 1 : 0)

                        matchAvatar(url: nil)
                            .offset(x: avatarsVisible ? 0 : 40)
                            .opacity(avatarsVisible ? 1 : 0)
                    }

                    // Heart center
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.eliteAccent, .eliteAccentMuted],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(avatarsVisible ? 1 : 0)
                        .opacity(avatarsVisible ? 1 : 0)
                }

                // Title
                VStack(spacing: EliteSpacing.sm) {
                    Text("It's a")
                        .font(EliteFont.bodyLarge())
                        .foregroundColor(.eliteTextSecondary)

                    Text("Match")
                        .font(EliteFont.displayXLarge())
                        .foregroundColor(.eliteAccent)
                        .tracking(3)
                        .shadow(color: .eliteAccent.opacity(0.3), radius: 20, y: 0)
                }
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 15)

                if let name = match.otherProfile?.displayName {
                    Text("You and \(name) liked each other")
                        .font(EliteFont.bodyMedium())
                        .foregroundColor(.eliteTextTertiary)
                        .opacity(titleVisible ? 1 : 0)
                }

                Spacer()

                // Action buttons
                VStack(spacing: EliteSpacing.md) {
                    // Send message — gradient CTA
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    } label: {
                        HStack(spacing: EliteSpacing.sm) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                            Text("SEND A MESSAGE")
                                .font(EliteFont.labelLarge())
                                .tracking(1.5)
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
                        .shadow(color: .eliteAccent.opacity(0.3), radius: 16, y: 6)
                    }

                    EliteButton(title: "KEEP SWIPING", style: .secondary) {
                        dismiss()
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.xxl)
                .opacity(buttonsVisible ? 1 : 0)
                .offset(y: buttonsVisible ? 0 : 20)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            runCelebration()
        }
    }

    private func matchAvatar(url: String?) -> some View {
        AvatarView(imageURL: url, size: 100)
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.eliteAccent.opacity(0.6), .eliteAccentMuted.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .eliteAccent.opacity(0.2), radius: 16, y: 0)
    }

    private func dismiss() {
        withAnimation(EliteAnimation.smooth) {
            buttonsVisible = false
            titleVisible = false
            avatarsVisible = false
            ringOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    private func runCelebration() {
        // Phase 1: Rings expand
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            ringScale = 1.0
            ringOpacity = 1
        }

        // Phase 2: Avatars slide in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4)) {
            avatarsVisible = true
        }

        // Phase 3: Title reveals
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            titleVisible = true
        }

        // Phase 4: Buttons slide up
        withAnimation(.easeOut(duration: 0.4).delay(1.2)) {
            buttonsVisible = true
        }

        // Phase 5: Particles burst
        spawnParticles()

        // Phase 6: Breathing glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }

    private func spawnParticles() {
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 40)
        let colors: [Color] = [.eliteAccent, .eliteAccentMuted, .eliteAccent.opacity(0.7)]

        for i in 0..<25 {
            let angle = Double.random(in: 0...Double.pi * 2)
            let distance = CGFloat.random(in: 60...200)
            let particle = MatchParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 2...5),
                position: center,
                opacity: 0
            )
            particles.append(particle)

            withAnimation(.easeOut(duration: 1.2).delay(0.5 + Double(i) * 0.03)) {
                particles[i].position = CGPoint(
                    x: center.x + cos(angle) * distance,
                    y: center.y + sin(angle) * distance
                )
                particles[i].opacity = Double.random(in: 0.3...0.7)
            }

            withAnimation(.easeIn(duration: 0.8).delay(1.8 + Double(i) * 0.02)) {
                particles[i].opacity = 0
            }
        }
    }
}

private struct MatchParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}
