import SwiftUI

// This new view provides a non-intrusive "toast" notification
// that appears at the top of the screen when an animal is unlocked.
struct UnlockToastView: View {
    let animal: Animal
    @State private var sparkle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(animal.rarity.color.opacity(0.35))
                    .frame(width: 82, height: 82)
                    .scaleEffect(sparkle ? 1.12 : 0.88)
                    .blur(radius: 5)

                Image(animal.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(sparkle ? 4 : -4))
                    .scaleEffect(sparkle ? 1.06 : 0.98)
            }

            VStack(alignment: .leading) {
                Text("Unlocked!")
                    .font(.caption.weight(.heavy))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .tracking(1.1)
                Text(animal.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .premiumGlass(cornerRadius: 22, tint: animal.rarity.color.opacity(0.32), interactive: false)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            guard !reduceMotion else { return }
            sparkle = true
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.72).repeatForever(autoreverses: true), value: sparkle)
    }
}
