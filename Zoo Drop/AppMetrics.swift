import Foundation
import CoreGraphics

struct AppMetrics {
    // --- THIS IS THE FIX ---
    // Reduced gravity for a slower, more controlled fall.
    static let gravityForce: CGFloat = -4.0
    
    static let foulLineHeightPercentage: CGFloat = 0.85

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
}
