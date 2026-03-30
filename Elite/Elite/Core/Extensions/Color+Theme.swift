import SwiftUI

extension Color {
    static var eliteGradientOverlay: LinearGradient {
        LinearGradient(
            colors: [.clear, .clear, .black.opacity(0.3), .black.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var eliteAccentGradient: LinearGradient {
        LinearGradient(
            colors: [.eliteAccent, .eliteAccentMuted],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var eliteSurfaceGradient: LinearGradient {
        LinearGradient(
            colors: [.eliteSurface, .eliteSurfaceElevated],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
