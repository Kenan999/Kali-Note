import SwiftUI

struct AppLogoView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background Glow (optional, matches premium theme)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.2)
            
            // Pen Nib / Rocket Body
            VStack(spacing: -size * 0.1) {
                // The Sharp Nib Top
                Path { path in
                    path.move(to: CGPoint(x: size * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.4))
                    path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.4))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size * 0.4)
                
                // The Main Rocket Body (Pen barrel)
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(Color.white)
                    .frame(width: size * 0.3, height: size * 0.5)
                
                // Rocket Engine / Pen End
                HStack(spacing: size * 0.05) {
                    RocketEngineFlame(size: size * 0.15)
                    RocketEngineFlame(size: size * 0.2)
                    RocketEngineFlame(size: size * 0.15)
                }
                .offset(y: size * 0.05)
            }
            .frame(width: size, height: size)
            .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct RocketEngineFlame: View {
    let size: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: size * 0.5, y: 0))
            path.addQuadCurve(to: CGPoint(x: size * 0.1, y: size), control: CGPoint(x: 0, y: size * 0.5))
            path.addLine(to: CGPoint(x: size * 0.9, y: size))
            path.addQuadCurve(to: CGPoint(x: size * 0.5, y: 0), control: CGPoint(x: size, y: size * 0.5))
        }
        .fill(LinearGradient(colors: [.white, .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AppLogoView(size: 100)
    }
}
