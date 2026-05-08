import Foundation
import CoreGraphics

struct AppMetrics {
    static let gravityForce: CGFloat = -5.1
    
    static let foulLineHeightPercentage: CGFloat = 0.58
    static let playfieldFloorClearance: CGFloat = 176

    // Power-Up Costs
    static let nudgeCostInGoldenEggs = 10
    static let rerollCostInGoldenEggs = 5

    // Scoring System Constants
    struct Scoring {
        static let baseMergeScore = 50
        static let comboMultiplier = 2.0
        static let heightBonusMultiplier = 0.1
    }
    
    static let maxRevivesPerSession = 1

    struct GameModes {
        static let deterministicQueueLength = 96
        static let timedStampedeDuration: TimeInterval = 90
        static let defaultChallengeTargetScore = 3_000
        static let defaultChallengeTargetMerges = 18
        static let defaultChallengeTargetCombo = 5
        static let dailySafariUnlockScore = 500
        static let challengeUnlockScore = 1_000
    }
}
