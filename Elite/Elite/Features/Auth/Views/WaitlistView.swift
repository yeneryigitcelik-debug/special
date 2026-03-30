import SwiftUI
import UserNotifications

struct WaitlistView: View {
    @EnvironmentObject var router: AppRouter
    @State private var animatedPosition: Int = 0
    @State private var showNotificationPrompt = false
    private let waitlistPosition = 847

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: EliteSpacing.xxl) {
                Spacer()

                VStack(spacing: EliteSpacing.lg) {
                    Text("You're on\nthe List")
                        .font(EliteFont.displayMedium())
                        .foregroundColor(.eliteTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    VStack(spacing: EliteSpacing.sm) {
                        Text("#\(animatedPosition)")
                            .font(EliteFont.displayHero())
                            .foregroundColor(.eliteAccent)
                            .contentTransition(.numericText())

                        Text("in line")
                            .font(EliteFont.bodyLarge())
                            .foregroundColor(.eliteTextSecondary)
                    }

                    estimatedWaitView

                    progressBar
                }

                Spacer()

                VStack(spacing: EliteSpacing.md) {
                    EliteButton(title: "INVITE A FRIEND TO SKIP THE LINE", style: .primary) {
                        shareInviteLink()
                    }

                    EliteButton(title: "NOTIFY ME WHEN IT'S MY TURN", style: .secondary) {
                        requestNotificationPermission()
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.bottom, EliteSpacing.xxl)
            }
        }
        .hideNavigationBar()
        .onAppear {
            animateCounter()
        }
    }

    private var estimatedWaitView: some View {
        HStack(spacing: EliteSpacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 14))
            Text("Estimated wait: \(estimatedDays) days")
                .font(EliteFont.bodyMedium())
        }
        .foregroundColor(.eliteTextTertiary)
        .padding(.top, EliteSpacing.sm)
    }

    private var progressBar: some View {
        VStack(spacing: EliteSpacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.eliteSurfaceElevated)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.eliteAccent)
                        .frame(width: geo.size.width * progressFraction, height: 4)
                        .animation(EliteAnimation.slow, value: animatedPosition)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, EliteSpacing.xxl)
        }
    }

    private var estimatedDays: Int {
        max(1, waitlistPosition / 50)
    }

    private var progressFraction: CGFloat {
        max(0.05, 1.0 - CGFloat(animatedPosition) / 2000.0)
    }

    private func animateCounter() {
        let steps = 30
        let delay = 1.0 / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delay) {
                withAnimation(.easeOut(duration: 0.05)) {
                    animatedPosition = Int(Double(waitlistPosition) * Double(i) / Double(steps))
                }
            }
        }
    }

    private func shareInviteLink() {
        let url = URL(string: "https://elite.dating/invite")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}

#Preview {
    WaitlistView()
        .environmentObject(AppRouter())
}
