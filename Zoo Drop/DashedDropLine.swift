import SwiftUI

struct DashedDropLine: View {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
            }
            .stroke(
                LinearGradient(colors: [.white.opacity(0.05), PremiumTheme.gold.opacity(0.85), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 11], dashPhase: phase)
            )
            .shadow(color: PremiumTheme.gold.opacity(0.65), radius: 8)
            .frame(width: 2)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 0.55).repeatForever(autoreverses: false)) {
                    phase = -21
                }
            }
        }
    }
}
