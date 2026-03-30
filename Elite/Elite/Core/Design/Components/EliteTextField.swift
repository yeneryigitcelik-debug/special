import SwiftUI

struct EliteTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var icon: String? = nil
    var characterLimit: Int? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: EliteSpacing.xs) {
            HStack(spacing: EliteSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? .eliteAccent : .eliteTextTertiary)
                }

                if isSecure {
                    SecureField("", text: $text, prompt: promptText)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text, prompt: promptText)
                        .focused($isFocused)
                }
            }
            .font(EliteFont.bodyLarge())
            .foregroundColor(.eliteTextPrimary)
            .padding(.horizontal, EliteSpacing.md)
            .frame(height: 52)
            .background(Color.eliteSurface)
            .cornerRadius(EliteRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: EliteRadius.medium)
                    .strokeBorder(
                        isFocused ? Color.eliteAccent.opacity(0.5) : Color.eliteDivider,
                        lineWidth: 1
                    )
            )
            .animation(EliteAnimation.smooth, value: isFocused)

            if let limit = characterLimit {
                Text("\(text.count)/\(limit)")
                    .font(EliteFont.caption())
                    .foregroundColor(text.count > limit ? .eliteError : .eliteTextTertiary)
            }
        }
        .onChange(of: text) { _, newValue in
            if let limit = characterLimit, newValue.count > limit {
                text = String(newValue.prefix(limit))
            }
        }
    }

    private var promptText: Text {
        Text(placeholder)
            .foregroundColor(.eliteTextTertiary)
    }
}

#Preview {
    VStack(spacing: 16) {
        EliteTextField(placeholder: "Display Name", text: .constant(""), icon: "person")
        EliteTextField(placeholder: "Bio", text: .constant("Hello world"), characterLimit: 300)
    }
    .padding(24)
    .background(Color.eliteBackground)
}
