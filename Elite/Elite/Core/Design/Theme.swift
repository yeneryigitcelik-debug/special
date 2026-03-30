import SwiftUI

// MARK: - Colors
extension Color {
    static let eliteBackground = Color(hex: "#1A1814")
    static let eliteSurface = Color(hex: "#242019")
    static let eliteSurfaceElevated = Color(hex: "#2E2A22")
    static let eliteAccent = Color(hex: "#D4C5A9")
    static let eliteAccentMuted = Color(hex: "#A89878")
    static let eliteTextPrimary = Color(hex: "#F5F0E8")
    static let eliteTextSecondary = Color(hex: "#9C9488")
    static let eliteTextTertiary = Color(hex: "#6B6560")
    static let eliteSuccess = Color(hex: "#7A9E7E")
    static let eliteError = Color(hex: "#C47D7D")
    static let eliteDivider = Color(hex: "#2E2A22")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
enum EliteFont {
    static func displayHero() -> Font { .custom("PlayfairDisplay-Bold", size: 64) }
    static func displayXLarge() -> Font { .custom("PlayfairDisplay-Bold", size: 48) }
    static func displayLarge() -> Font { .custom("PlayfairDisplay-Bold", size: 34) }
    static func displayMedium() -> Font { .custom("PlayfairDisplay-Bold", size: 28) }
    static func displaySmall() -> Font { .custom("PlayfairDisplay-Regular", size: 24) }

    static func headlineLarge() -> Font { .custom("CormorantGaramond-Medium", size: 22) }
    static func headlineMedium() -> Font { .custom("CormorantGaramond-Medium", size: 18) }
    static func bodyLarge() -> Font { .custom("CormorantGaramond-Regular", size: 17) }
    static func bodyMedium() -> Font { .custom("CormorantGaramond-Regular", size: 15) }
    static func bodySmall() -> Font { .custom("CormorantGaramond-Light", size: 13) }

    static func labelLarge() -> Font { .system(size: 15, weight: .medium) }
    static func labelMedium() -> Font { .system(size: 13, weight: .medium) }
    static func labelSmall() -> Font { .system(size: 11, weight: .medium) }
    static func caption() -> Font { .system(size: 11, weight: .regular) }
}

// MARK: - Spacing
enum EliteSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius
enum EliteRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Shadows
enum EliteShadow {
    static let subtle = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let medium = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    static let heavy = Shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Animation
enum EliteAnimation {
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let medium = Animation.easeInOut(duration: 0.4)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.interpolatingSpring(stiffness: 200, damping: 20)
}
