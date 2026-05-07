import SwiftUI

// UIUX-01: The ChuteView now has an anticipation "wiggle" animation.
struct ChuteView: View {
    let nextAnimal: Animal?
    let isAiming: Bool
    @Binding var isWiggling: Bool

    @State private var animateBlink = false
    @State private var idleTilt = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(PremiumTheme.mint.opacity(isAiming ? 0.3 : 0.14))
                .frame(width: 94, height: 94)
                .blur(radius: 14)
                .scaleEffect(idleTilt ? 1.08 : 0.92)

            Image("chute")
                .resizable()
                .scaledToFit()
                .frame(width: 70)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)

            if let animal = nextAnimal {
                ZStack {
                    Image(animal.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .scaleEffect(idleTilt ? 1.04 : 0.98)
                        .rotationEffect(.degrees(isAiming ? 0 : (idleTilt ? 3 : -3)))

                    EyeBlinkOverlay()
                        .frame(width: 52, height: 52)
                        .opacity(animateBlink ? 1 : 0)
                }
                .opacity(isAiming ? 1.0 : 0.9)
            }
        }
        .rotationEffect(.degrees(isWiggling ? 5 : 0))
        .onAppear {
            if !reduceMotion {
                animateBlink = true
                idleTilt = true
            }
        }
        .onChange(of: isAiming) {
            animateBlink = !isAiming && !reduceMotion
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12).delay(1.8).repeatForever(autoreverses: true), value: animateBlink)
    }
}

private struct EyeBlinkOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            HStack(spacing: size * 0.22) {
                Capsule()
                    .fill(.black.opacity(0.64))
                Capsule()
                    .fill(.black.opacity(0.64))
            }
            .frame(width: size * 0.44, height: size * 0.055)
            .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.39)
        }
        .allowsHitTesting(false)
    }
}
