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
    let canRevive: Bool

    let largestAnimal: String
    let longestCombo: Int
    
    @State private var displayedScore: Int = 0
    @State private var scaleEffect: CGFloat = 0.8
    @State private var isSharing = false // State to show activity indicator

    var body: some View {
        ZStack {
            Image("gameover")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Text("\(displayedScore)")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(radius: 3)
                
                VStack(spacing: 6) {
                    Text("Largest Animal: \(largestAnimal)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Longest Combo: \(longestCombo)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                    
                VStack(spacing: 15) {
                    if canRevive {
                        Button(action: onRevive) {
                            Label("Revive with Ad", systemImage: "play.tv.fill")
                                .font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding().background(Color.purple).cornerRadius(12)
                        }
                    }
                    
                    // --- VIR-01: UPDATED SHARE BUTTON ---
                    Button(action: shareAction) {
                        if isSharing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 24) // Match button height
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(12)
                        } else {
                            Label("Share as GIF", systemImage: "square.and.arrow.up")
                                .font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding().background(Color.blue).cornerRadius(12)
                        }
                    }
                    .disabled(isSharing || frames == nil) // Disable if sharing or no frames are available

                    Button(action: onRetry) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity)
                            .padding().background(Color.green).cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .scaleEffect(scaleEffect)
            .onAppear {
                animateScore()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scaleEffect = 1.0
                }
            }
        }
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
