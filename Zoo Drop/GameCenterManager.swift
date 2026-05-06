import Foundation
import GameKit
import UIKit

enum GameCenterError: Error {
    case leaderboardNotFound
    case authenticationFailed
}

// --- RET-01: ACHIEVEMENT & LEADERBOARD IDENTIFIERS ---
// Defines specific identifiers for all achievements in the game.
enum AchievementID: String, CaseIterable {
    case firstMerge = "zoodrop.achievement.firstmerge"
    case createdPanda = "zoodrop.achievement.createdpanda"
    case createdLion = "zoodrop.achievement.createdlion"
    case score10k = "zoodrop.achievement.score10k"
    case score50k = "zoodrop.achievement.score50k"
}

// Defines specific identifiers for all leaderboards.
enum LeaderboardID: String, CaseIterable {
    case mainHighscore = "zoodrop.highscore"
    case totalMerges = "zoodrop.totalmerges" // Tracks lifetime merges
    case largestAnimal = "zoodrop.largestanimal" // Tracks the highest tier animal created
}
// --- END RET-01 IMPLEMENTATION ---

class GameCenterManager: NSObject, ObservableObject {
    
    // --- RET-01: UPDATED LEADERBOARD IDs ---
    // The list of all leaderboard IDs is now derived from the enum for type safety and clarity.
    var leaderboardIDs: [String] = LeaderboardID.allCases.map { $0.rawValue }
    
    @Published var isAuthenticated = false
    @Published var authErrorMessage: String? = nil
    @Published var isAuthenticating = false

    override init() {
        super.init()
    }
    
    func authenticateUser() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authErrorMessage = nil
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAuthenticating = false
                if let vc = vc {
                    if let rootVC = UIViewController.findRootViewController() {
                        if rootVC.presentedViewController == nil {
                            rootVC.present(vc, animated: true)
                        }
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.authErrorMessage = nil
                    print("✅ Game Center authenticated")
                } else {
                    self.isAuthenticated = false
                    self.authErrorMessage = error?.localizedDescription ?? "Authentication failed"
                }
            }
        }
    }
    
    // --- RET-01: ACHIEVEMENT REPORTING ---
    /// Reports the progress of a specific achievement to Game Center.
    /// - Parameters:
    ///   - id: The specific achievement being updated.
    ///   - percentComplete: The completion percentage (0-100).
    func reportAchievement(id: AchievementID, percentComplete: Double) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: id.rawValue)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true // Show a banner when 100% is reached.
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("❌ Failed to report achievement \(id.rawValue): \(error.localizedDescription)")
            } else {
                print("✅ Achievement \(id.rawValue) progress reported: \(percentComplete)%")
            }
        }
    }

    /// Submits a score to a specific leaderboard.
    /// - Parameters:
    ///   - score: The score value to submit.
    ///   - leaderboardID: The enum case for the target leaderboard.
    func submitScore(_ score: Int, to leaderboardID: LeaderboardID) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit score to \(leaderboardID.rawValue) — user not authenticated")
            return
        }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID.rawValue]) { error in
            if let error = error {
                print("❌ Failed to report score to \(leaderboardID.rawValue): \(error.localizedDescription)")
            } else {
                print("✅ Score \(score) submitted to leaderboard \(leaderboardID.rawValue)")
            }
        }
    }
    
    /// Presents the native Game Center dashboard for achievements.
    func showAchievements() {
        guard isAuthenticated, let rootVC = UIViewController.findRootViewController() else { return }
        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }
    
    /// Presents the native Game Center dashboard for leaderboards.
    func showLeaderboards() {
        guard isAuthenticated, let rootVC = UIViewController.findRootViewController() else { return }
        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }

    func fetchLeaderboardScores() async throws -> [LeaderboardEntry] {
        guard isAuthenticated else { throw GameCenterError.authenticationFailed }
        guard let leaderboard = try await GKLeaderboard.loadLeaderboards(IDs: [LeaderboardID.mainHighscore.rawValue]).first else {
            throw GameCenterError.leaderboardNotFound
        }
        let (_, entries, _) = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 25))
        return entries.map { LeaderboardEntry(name: $0.player.displayName, score: $0.score) }
    }
}

// --- RET-01: GAME CENTER DELEGATE ---
// Conforming to the delegate protocol to handle dismissing the Game Center view controller.
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
