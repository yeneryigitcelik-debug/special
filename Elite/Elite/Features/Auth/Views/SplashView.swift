import SwiftUI

struct SplashView: View {
    @State private var particles: [SplashParticle] = []
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var lineWidth: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            // Ambient radial glow
            RadialGradient(
                colors: [
                    Color.eliteAccent.opacity(0.06),
                    Color.eliteAccent.opacity(0.02),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .opacity(glowOpacity)
            .ignoresSafeArea()

            // Floating particles
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.eliteAccent.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.size > 3 ? 1 : 0)
                    .position(particle.position)
            }

            // Logo constellation
            VStack(spacing: EliteSpacing.lg) {
                // Logo with glow
                Text("ÉLITE")
                    .font(.custom("PlayfairDisplay-Bold", size: 42))
                    .tracking(12)
                    .foregroundColor(.eliteAccent)
                    .shadow(color: .eliteAccent.opacity(glowOpacity * 0.4), radius: glowRadius, x: 0, y: 0)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                // Animated divider line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .eliteAccent.opacity(0.6), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: lineWidth, height: 0.5)

                // Subtitle
                Text("CURATED CONNECTIONS")
                    .font(EliteFont.labelSmall())
                    .tracking(4)
                    .foregroundColor(.eliteTextTertiary)
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            spawnParticles()
            runSequence()
        }
    }

    private func runSequence() {
        // Phase 1: Glow appears (0.4s delay)
        withAnimation(.easeIn(duration: 1.5).delay(0.4)) {
            glowOpacity = 1
            glowRadius = 30
        }

        // Phase 2: Logo fades in + scales (0.8s delay)
        withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
            logoOpacity = 1
            logoScale = 1.0
        }

        // Phase 3: Line expands (1.5s delay)
        withAnimation(.easeInOut(duration: 0.8).delay(1.5)) {
            lineWidth = 80
        }

        // Phase 4: Subtitle fades (2.0s delay)
        withAnimation(.easeIn(duration: 0.6).delay(2.0)) {
            subtitleOpacity = 1
        }

        // Phase 5: Breathing glow loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.5
                glowRadius = 40
            }
        }
    }

    private func spawnParticles() {
        let screen = UIScreen.main.bounds
        for i in 0..<30 {
            let particle = SplashParticle(
                id: i,
                size: CGFloat.random(in: 1.5...4),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screen.width),
                    y: CGFloat.random(in: 0...screen.height)
                ),
                opacity: 0
            )
            particles.append(particle)
        }

        // Fade particles in with staggered delay
        for i in particles.indices {
            let delay = Double.random(in: 0.5...2.5)
            withAnimation(.easeInOut(duration: 1.5).delay(delay)) {
                particles[i].opacity = Double.random(in: 0.1...0.35)
            }
        }

        // Drift particles slowly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                for i in particles.indices {
                    particles[i].position.y += CGFloat.random(in: -30...30)
                    particles[i].position.x += CGFloat.random(in: -15...15)
                }
            }
        }
    }
}

private struct SplashParticle: Identifiable {
    let id: Int
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    SplashView()
}
