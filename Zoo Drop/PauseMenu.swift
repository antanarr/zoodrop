import SwiftUI

struct PauseMenu: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    @State private var showingConfirmation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Game Paused")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .accessibilityLabel("Game Paused")
                    .accessibilityHint("You have paused the game")

                Button(action: { onResume() }) {
                    Text("Resume")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Resume Game")
                .accessibilityHint("Tap to continue your current game")

                Button(action: { onRestart() }) {
                    Text("Restart")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Restart Game")
                .accessibilityHint("Tap to start the game over from the beginning")

                Button(action: {
                    showingConfirmation = true
                }) {
                    Text("Quit")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Quit Game")
                .accessibilityHint("Tap to exit the current game and return to the main menu")
            }
            .padding()
            .background(Color("BackgroundColor"))
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .confirmationDialog("Are you sure you want to quit?", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("Quit", role: .destructive) {
                    onQuit()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct PauseMenu_Previews: PreviewProvider {
    static var previews: some View {
        PauseMenu(
            onResume: {},
            onRestart: {},
            onQuit: {}
        )
    }
}
