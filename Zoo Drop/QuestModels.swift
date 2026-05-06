import Foundation

/// Defines the different kinds of tasks a player can be asked to complete.
enum QuestType: Codable {
    case reachScore(Int)
    case dropSpecificAnimal(name: String, count: Int)
    case surviveDrops(Int)
}

/// Represents a single quest or mission for the player.
struct Quest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: QuestType
    var progress: Int = 0
    var isComplete: Bool = false
    
    // The reward for completing the quest, e.g., number of Golden Eggs.
    let reward: Int

    /// A computed property to check if the quest goal has been met.
    var goalReached: Bool {
        switch type {
        case .reachScore(let goal):
            return progress >= goal
        case .dropSpecificAnimal(_, let goal):
            return progress >= goal
        case .surviveDrops(let goal):
            return progress >= goal
        }
    }
}
