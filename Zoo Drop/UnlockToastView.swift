import SwiftUI

// This new view provides a non-intrusive "toast" notification
// that appears at the top of the screen when an animal is unlocked.
struct UnlockToastView: View {
    let animal: Animal

    var body: some View {
        HStack(spacing: 16) {
            Image(animal.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(8)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading) {
                Text("Unlocked!")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(animal.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
        // Animate its appearance and disappearance from the top edge.
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
