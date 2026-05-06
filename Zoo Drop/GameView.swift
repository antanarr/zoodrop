import Foundation

class GameViewModel: ObservableObject {
    // ... existing properties and methods ...
    
    func didMergeInitialAnimal(newAnimal: Animal) {
        // ... existing logic for merging animals and updating score ...
        
        if newAnimal.name == "Panda" {
            gameCenterManager.reportAchievement(id: .createdPanda, percentComplete: 100.0)
        }
        gameCenterManager.reportAchievement(id: .firstMerge, percentComplete: 100.0)
    }
    
    func didTriggerGameOverWithFrames(_ frames: [Frame], score: Int) {
        // ... existing logic for submitting scores ...
        
        if score >= 10000 {
            gameCenterManager.reportAchievement(id: .score10k, percentComplete: 100.0)
        }
    }
    
    func dropAnimal() {
        // ... existing logic for dropping animal ...
        
        questManager.processEvent(type: .dropSurvived)
    }
}
