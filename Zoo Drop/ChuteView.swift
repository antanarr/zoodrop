import SwiftUI

// UIUX-01: The ChuteView now has an anticipation "wiggle" animation.
struct ChuteView: View {
    let nextAnimal: Animal?
    let isAiming: Bool
    @Binding var isWiggling: Bool

    @State private var idleTilt = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(PremiumTheme.gold.opacity(isAiming ? 0.22 : 0.12))
                .frame(width: 100, height: 100)
                .blur(radius: 16)
                .scaleEffect(idleTilt ? 1.03 : 0.98)

            Image("chute")
                .resizable()
                .scaledToFit()
                .frame(width: 70)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)

            if let animal = nextAnimal {
                Image(animal.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .scaleEffect(idleTilt ? 1.025 : 0.995)
                    .rotationEffect(.degrees(isAiming ? 0 : (idleTilt ? 1.4 : -1.4)))
                .opacity(isAiming ? 1.0 : 0.9)
            }
        }
        .rotationEffect(.degrees(isWiggling ? 5 : 0))
        .onAppear {
            if !reduceMotion {
                idleTilt = true
            }
        }
        .onChange(of: isWiggling) {
            if isWiggling {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isWiggling = false
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: idleTilt)
        .animation(.spring(response: 0.22, dampingFraction: 0.36), value: isWiggling)
    }
}
