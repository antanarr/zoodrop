import Foundation
import SwiftUI

@MainActor
// 1. REMOVED SINGLETON: This class is now instantiated in Zoo_DropApp.
class ZooDexManager: ObservableObject {
    
    @Published var unlockedAnimalNames: Set<String> {
        didSet {
            saveUnlocked()
        }
    }

    private let unlocksKey = "ZooDexUnlockedAnimals"

    // 2. PUBLIC INITIALIZER
    init() {
        if let saved = UserDefaults.standard.array(forKey: unlocksKey) as? [String] {
            unlockedAnimalNames = Set(saved)
        } else {
            unlockedAnimalNames = ["Monkey"]
        }
    }

    func isUnlocked(_ animal: Animal) -> Bool {
        unlockedAnimalNames.contains(animal.name)
    }

    func unlock(_ animal: Animal) {
        unlockedAnimalNames.insert(animal.name)
    }

    private func saveUnlocked() {
        UserDefaults.standard.set(Array(unlockedAnimalNames), forKey: unlocksKey)
    }
}
