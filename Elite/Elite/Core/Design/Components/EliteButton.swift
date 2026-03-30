import SwiftUI

struct EliteButton: View {
    let title: String
    let style: Style
    var isLoading: Bool = false
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case text
        case destructive
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    Text(title)
                        .font(EliteFont.labelLarge())
                        .tracking(1.2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(EliteRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: EliteRadius.medium)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .eliteAccent
        case .secondary: return .clear
        case .text: return .clear
        case .destructive: return .eliteError.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .eliteBackground
        case .secondary: return .eliteAccent
        case .text: return .eliteAccent
        case .destructive: return .eliteError
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return .eliteAccent.opacity(0.4)
        default: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EliteButton(title: "ENTER ÉLITE", style: .primary) {}
        EliteButton(title: "APPLY TO JOIN", style: .secondary) {}
        EliteButton(title: "Skip", style: .text) {}
        EliteButton(title: "Delete Account", style: .destructive) {}
        EliteButton(title: "Loading...", style: .primary, isLoading: true) {}
    }
    .padding(24)
    .background(Color.eliteBackground)
}
