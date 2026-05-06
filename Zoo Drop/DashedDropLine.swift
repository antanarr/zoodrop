import SwiftUI

struct DashedDropLine: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 10]))
            .foregroundColor(Color.white.opacity(0.3))
            .frame(width: 2)
        }
    }
}
