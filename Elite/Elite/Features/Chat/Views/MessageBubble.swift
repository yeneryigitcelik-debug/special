import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isSent: Bool
    var showTimestamp: Bool = false

    var body: some View {
        VStack(alignment: isSent ? .trailing : .leading, spacing: 3) {
            HStack {
                if isSent { Spacer(minLength: 60) }

                Text(message.content)
                    .font(EliteFont.bodyMedium())
                    .foregroundColor(isSent ? .eliteBackground : .eliteTextPrimary)
                    .padding(.horizontal, EliteSpacing.md)
                    .padding(.vertical, EliteSpacing.sm + 3)
                    .background(
                        isSent
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [.eliteAccent, .eliteAccentMuted.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                          )
                        : AnyShapeStyle(Color.eliteSurface)
                    )
                    .clipShape(BubbleShape(isSent: isSent))

                if !isSent { Spacer(minLength: 60) }
            }

            if showTimestamp {
                HStack(spacing: EliteSpacing.xs) {
                    Text(message.createdAt.messageBubbleTime)
                        .font(EliteFont.caption())
                        .foregroundColor(.eliteTextTertiary)

                    if isSent {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 10))
                            .foregroundColor(message.isRead ? .eliteAccentMuted : .eliteTextTertiary)
                    }
                }
                .padding(.horizontal, EliteSpacing.xs)
            }
        }
    }
}

// MARK: - Custom Bubble Shape
struct BubbleShape: Shape {
    let isSent: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailRadius: CGFloat = 6

        var path = Path()

        if isSent {
            // Sent: all corners rounded except bottom-right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailRadius))
            path.addArc(center: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY - tailRadius),
                       radius: tailRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Received: all corners rounded except bottom-left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + tailRadius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + tailRadius, y: rect.maxY - tailRadius),
                       radius: tailRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.eliteTextTertiary)
                    .frame(width: 6, height: 6)
                    .opacity(dotOpacities[index])
            }
        }
        .padding(.horizontal, EliteSpacing.md)
        .padding(.vertical, EliteSpacing.sm + 3)
        .background(Color.eliteSurface)
        .clipShape(BubbleShape(isSent: false))
        .onAppear {
            for i in 0..<3 {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15)) {
                    dotOpacities[i] = 1.0
                }
            }
        }
    }
}
