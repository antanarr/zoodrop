import Foundation
import CoreGraphics
import SwiftUI

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case classic
    case dailySafari
    case timedStampede
    case zen
    case challenge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .dailySafari: return "Daily Safari"
        case .timedStampede: return "Timed Stampede"
        case .zen: return "Zen"
        case .challenge: return "Challenge"
        }
    }

    var allowsGameOver: Bool {
        self != .zen
    }

    var usesDeterministicQueue: Bool {
        switch self {
        case .dailySafari, .challenge:
            return true
        case .classic, .timedStampede, .zen:
            return false
        }
    }

    var scoreMultiplier: Double {
        switch self {
        case .classic, .dailySafari, .challenge:
            return 1.0
        case .timedStampede:
            return 1.25
        case .zen:
            return 0.7
        }
    }

    var timeLimit: TimeInterval? {
        switch self {
        case .timedStampede:
            return AppMetrics.GameModes.timedStampedeDuration
        case .classic, .dailySafari, .zen, .challenge:
            return nil
        }
    }
}

enum Rarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary, mythical
}

enum AnimalAbility: String, Codable {
    case roar, pounce, heavyweight, windGust
}

struct Animal: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let imageName: String
    let rarity: Rarity
    let scoreValue: Int
    let mergeResult: String?
    let ability: AnimalAbility?
    var cosmeticSkinID: String?

    let mass: CGFloat
    let friction: CGFloat
    let restitution: CGFloat
    
    let isSubscriberExclusive: Bool?

    var unlockThreshold: Int {
        max(0, scoreValue)
    }
}

enum TutorialStep: String, Codable, CaseIterable, Hashable {
    case firstAim
    case firstDrop
    case firstMerge
    case firstCombo
    case firstPowerUp
    case firstRevive
    case firstDailyRun
    case firstTimedRun
    case firstZenRun
    case firstChallengeRun
}

enum GameplayAchievementID: String, Codable, CaseIterable, Hashable {
    case firstDrop
    case firstCombo
    case dailyExplorer
    case stampedeRunner
    case zenKeeper
    case challengeClear
    case chainMaster
    case elephantKeeper
    case scoreClimber
    case scoreChampion
}

struct ChallengeProgress: Codable, Equatable {
    let challengeID: String
    var targetScore: Int
    var targetMerges: Int
    var targetCombo: Int
    var bestScore: Int
    var merges: Int
    var bestCombo: Int

    init(
        challengeID: String,
        targetScore: Int = AppMetrics.GameModes.defaultChallengeTargetScore,
        targetMerges: Int = AppMetrics.GameModes.defaultChallengeTargetMerges,
        targetCombo: Int = AppMetrics.GameModes.defaultChallengeTargetCombo,
        bestScore: Int = 0,
        merges: Int = 0,
        bestCombo: Int = 0
    ) {
        self.challengeID = challengeID
        self.targetScore = targetScore
        self.targetMerges = targetMerges
        self.targetCombo = targetCombo
        self.bestScore = bestScore
        self.merges = merges
        self.bestCombo = bestCombo
    }

    var isComplete: Bool {
        bestScore >= targetScore || merges >= targetMerges || bestCombo >= targetCombo
    }

    mutating func record(score: Int, merges: Int, combo: Int) {
        bestScore = max(bestScore, score)
        self.merges = max(self.merges, merges)
        bestCombo = max(bestCombo, combo)
    }
}

struct PlayerProgressionMetrics: Codable, Equatable {
    var lifetimeScore: Int = 0
    var lifetimeDrops: Int = 0
    var lifetimeMerges: Int = 0
    var bestScore: Int = 0
    var bestCombo: Int = 0
    var largestAnimalTier: Int = 0
    var modeHighScores: [GameMode: Int] = [:]
    var completedTutorialSteps: Set<TutorialStep> = []
    var challengeCompletions: [String: Int] = [:]
    var unlockedAchievements: Set<GameplayAchievementID> = []

    mutating func recordDrop() {
        lifetimeDrops += 1
    }

    mutating func recordMerge(score: Int, combo: Int, animal: Animal) {
        lifetimeMerges += 1
        lifetimeScore += max(0, score)
        bestCombo = max(bestCombo, combo)
        largestAnimalTier = max(largestAnimalTier, AnimalLibrary.tierIndex(for: animal))
    }

    mutating func recordRunFinished(mode: GameMode, score: Int, combo: Int) {
        bestScore = max(bestScore, score)
        bestCombo = max(bestCombo, combo)
        modeHighScores[mode] = max(modeHighScores[mode, default: 0], score)
    }

    mutating func markTutorialStepComplete(_ step: TutorialStep) {
        completedTutorialSteps.insert(step)
    }

    mutating func recordChallengeCompletion(id: String) {
        challengeCompletions[id, default: 0] += 1
    }
}

struct SavedRunAnimalState: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var animalName: String
    var x: CGFloat
    var y: CGFloat
    var rotation: CGFloat
    var velocityDX: CGFloat
    var velocityDY: CGFloat
    var angularVelocity: CGFloat

    init(
        id: UUID = UUID(),
        animalName: String,
        x: CGFloat,
        y: CGFloat,
        rotation: CGFloat = 0,
        velocityDX: CGFloat = 0,
        velocityDY: CGFloat = 0,
        angularVelocity: CGFloat = 0
    ) {
        self.id = id
        self.animalName = animalName
        self.x = x
        self.y = y
        self.rotation = rotation
        self.velocityDX = velocityDX
        self.velocityDY = velocityDY
        self.angularVelocity = angularVelocity
    }
}

struct SavedRunSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    var createdAt: Date
    var mode: GameMode
    var score: Int
    var nextAnimalName: String?
    var queuedAnimalNames: [String]
    var queueCursor: Int
    var droppableAnimalNames: [String]
    var animalStates: [SavedRunAnimalState]
    var largestAnimalName: String?
    var longestCombo: Int
    var totalMerges: Int
    var drops: Int
    var canRevive: Bool
    var remainingTime: TimeInterval?
    var challengeProgress: ChallengeProgress?

    var isResumable: Bool {
        !animalStates.isEmpty || score > 0 || drops > 0
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    static func stableSeed(from string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        case .mythical: return Color(red: 0.4, green: 0.9, blue: 0.8)
        }
    }
}

extension AnimalAbility {
    var description: String {
        switch self {
        case .roar: return "King's Roar - Compacts animals below."
        case .pounce: return "Pounce - Lands with extra force."
        case .heavyweight: return "Heavyweight - Becomes an immovable anchor."
        case .windGust: return "Wind Gust - Pushes nearby animals sideways."
        }
    }
}
