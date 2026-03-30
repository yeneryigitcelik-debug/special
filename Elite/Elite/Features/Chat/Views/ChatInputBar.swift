import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.eliteDivider)
                .frame(height: 0.5)

            HStack(spacing: EliteSpacing.sm) {
                TextField("Message...", text: $text, axis: .vertical)
                    .font(EliteFont.bodyMedium())
                    .foregroundColor(.eliteTextPrimary)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, EliteSpacing.md)
                    .padding(.vertical, EliteSpacing.sm + 2)
                    .background(Color.eliteSurface)
                    .cornerRadius(22)
                    .tint(.eliteAccent)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSend()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canSend ? .eliteBackground : .eliteTextTertiary)
                        .frame(width: 34, height: 34)
                        .background(canSend ? Color.eliteAccent : Color.eliteSurface)
                        .clipShape(Circle())
                }
                .disabled(!canSend)
                .animation(EliteAnimation.smooth, value: canSend)
            }
            .padding(.horizontal, EliteSpacing.md)
            .padding(.vertical, EliteSpacing.sm)
            .background(Color.eliteBackground)
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputBar(text: .constant("Hello")) {}
    }
    .background(Color.eliteBackground)
}
