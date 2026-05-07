import SwiftUI

struct PauseMenu: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    @State private var showingConfirmation = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(PremiumTheme.gold)
                    .symbolEffect(.pulse, options: .repeating, value: appeared)

                Text("Game Paused")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .accessibilityLabel("Game Paused")
                    .accessibilityHint("You have paused the game")

                Button(action: { onResume() }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
                .accessibilityLabel("Resume Game")
                .accessibilityHint("Tap to continue your current game")
                .accessibilityIdentifier("resumeButton")

                Button(action: { onRestart() }) {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.gold))
                .accessibilityLabel("Restart Game")
                .accessibilityHint("Tap to start the game over from the beginning")
                .accessibilityIdentifier("restartButton")

                Button(action: {
                    showingConfirmation = true
                }) {
                    Label("Quit", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.coral, prominence: .destructive))
                .accessibilityLabel("Quit Game")
                .accessibilityHint("Tap to exit the current game and return to the main menu")
                .accessibilityIdentifier("quitButton")
            }
            .padding(22)
            .frame(maxWidth: 360)
            .premiumGlass(cornerRadius: 30, tint: PremiumTheme.lagoon.opacity(0.22))
            .padding(.horizontal, 28)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.86)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.72)) {
                    appeared = true
                }
            }
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
