import SwiftUI

// UIUX-01: The ChuteView now has an anticipation "wiggle" animation.
struct ChuteView: View {
    let nextAnimal: Animal?
    let isAiming: Bool
    // This new binding triggers the wiggle animation.
    @Binding var isWiggling: Bool

    @State private var animateBlink = false

    var body: some View {
        ZStack {
            Image("chute")
                .resizable()
                .scaledToFit()
                .frame(width: 70)

            if let animal = nextAnimal {
                Image(animal.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50)
                    .opacity(isAiming ? 1.0 : (animateBlink ? 0.4 : 0.8))
                    .animation(isAiming ? .none : Animation.easeInOut(duration: 0.7).repeatForever(), value: animateBlink)
            }
        }
        // The wiggle effect is a rotation that's applied when isWiggling is true.
        .rotationEffect(.degrees(isWiggling ? 5 : 0))
        .onAppear {
            if !isAiming {
                animateBlink = true
            }
        }
        .onChange(of: isAiming) {
            animateBlink = !isAiming
        }
        .onChange(of: isWiggling) {
            // When the wiggle starts, trigger a spring animation.
            if isWiggling {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    // The animation itself is handled by the .rotationEffect modifier.
                }
                // Reset the state after a short delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isWiggling = false
                }
            }
        }
    }
}
