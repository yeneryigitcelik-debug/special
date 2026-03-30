import SwiftUI

struct ParallaxModifier: ViewModifier {
    var magnitude: CGFloat = 20

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            content
                .offset(y: -minY * 0.3)
                .frame(width: geo.size.width, height: geo.size.height + magnitude * 2)
                .clipped()
        }
    }
}

extension View {
    func parallax(magnitude: CGFloat = 20) -> some View {
        modifier(ParallaxModifier(magnitude: magnitude))
    }
}
