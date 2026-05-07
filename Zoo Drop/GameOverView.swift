import SwiftUI
import SpriteKit

struct GameOverView: View {
    // --- VIR-01: INJECT SHAREMANAGER ---
    @EnvironmentObject var shareManager: ShareManager
    
    let score: Int
    // --- VIR-01: RECEIVE FRAMES ---
    let frames: [SKTexture]? // Property to hold the frames for the GIF
    
    let onRetry: () -> Void
    let onRevive: () -> Void
    var onQuit: (() -> Void)? = nil
    let canRevive: Bool

    let largestAnimal: String
    let longestCombo: Int
    
    @State private var displayedScore: Int = 0
    @State private var scaleEffect: CGFloat = 0.8
    @State private var isSharing = false // State to show activity indicator
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Image("gameover")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.72)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(PremiumTheme.gold.opacity(0.24))
                            .frame(width: 190, height: 190)
                            .blur(radius: 22)
                            .scaleEffect(glow ? 1.12 : 0.88)

                        VStack(spacing: 4) {
                            Text("Game Over")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 5)

                            Text("\(displayedScore)")
                                .font(.system(size: 68, weight: .black, design: .rounded))
                                .foregroundColor(PremiumTheme.gold)
                                .shadow(color: PremiumTheme.gold.opacity(0.65), radius: 14)
                                .monospacedDigit()
                                .accessibilityLabel("Final score \(score)")
                        }
                    }

                    HStack(spacing: 10) {
                        resultPill(title: "Largest", value: largestAnimal, icon: "pawprint.fill")
                        resultPill(title: "Combo", value: "\(longestCombo)x", icon: "sparkles")
                    }

                    VStack(spacing: 12) {
                        if canRevive {
                            Button(action: onRevive) {
                                Label("Revive", systemImage: "play.tv.fill")
                            }
                            .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.violet))
                            .accessibilityLabel("Revive with a rewarded ad")
                            .accessibilityIdentifier("reviveButton")
                        }

                        Button(action: shareAction) {
                            if isSharing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity, minHeight: 24)
                            } else {
                                Label("Share GIF", systemImage: "square.and.arrow.up")
                            }
                        }
                        .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.lagoon))
                        .disabled(isSharing || frames == nil)
                        .accessibilityLabel("Share collapse as GIF")
                        .accessibilityIdentifier("shareGIFButton")

                        Button(action: onRetry) {
                            Label("Play Again", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
                        .accessibilityIdentifier("playAgainButton")

                        if let onQuit {
                            Button(action: onQuit) {
                                Label("Menu", systemImage: "house.fill")
                            }
                            .buttonStyle(PremiumButtonStyle(tint: .white.opacity(0.36)))
                            .accessibilityIdentifier("gameOverMenuButton")
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 420)
                .premiumGlass(cornerRadius: 34, tint: PremiumTheme.coral.opacity(0.18))
                .padding(22)
            }
            .scrollIndicators(.hidden)
            .scaleEffect(scaleEffect)
            .onAppear {
                animateScore()
                glow = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scaleEffect = 1.0
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.25).repeatForever(autoreverses: true), value: glow)
        }
    }

    private func resultPill(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .premiumGlass(cornerRadius: 18, tint: PremiumTheme.mint.opacity(0.18))
    }
    
    // --- VIR-01: SHARE ACTION LOGIC ---
    private func shareAction() {
        guard let capturedFrames = frames, !capturedFrames.isEmpty, let rootVC = UIViewController.findRootViewController() else {
            print("❌ GameOverView: Cannot share. Frames are missing or root VC not found.")
            return
        }

        isSharing = true
        let shareText = "I scored \(score) in #ZooDrop! Check out my tower collapse!"
        
        shareManager.shareGIF(frames: capturedFrames, text: shareText, from: rootVC) {
            // This completion handler is called after the share sheet is dismissed.
            isSharing = false
        }
    }
    
    private func animateScore() {
        let duration = 1.0
        var startTime: TimeInterval = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { timer in
            if startTime == 0 { startTime = Date().timeIntervalSince1970 }
            
            let elapsed = Date().timeIntervalSince1970 - startTime
            let progress = min(elapsed / duration, 1.0)
            
            displayedScore = Int(Double(score) * progress)
            
            if progress == 1.0 {
                timer.invalidate()
            }
        }
        timer.fire()
    }
}
