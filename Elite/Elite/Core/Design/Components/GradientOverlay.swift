import SwiftUI

struct GradientOverlay: View {
    var style: Style = .bottom

    enum Style {
        case bottom
        case top
        case full
        case radial
    }

    var body: some View {
        switch style {
        case .bottom:
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.2), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .top:
            LinearGradient(
                colors: [.black.opacity(0.6), .black.opacity(0.2), .clear, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        case .full:
            LinearGradient(
                colors: [.black.opacity(0.4), .black.opacity(0.15), .black.opacity(0.15), .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .radial:
            RadialGradient(
                colors: [.clear, .black.opacity(0.4)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        }
    }
}

#Preview {
    ZStack {
        Color.eliteAccent
        GradientOverlay(style: .bottom)
    }
    .frame(height: 300)
}
