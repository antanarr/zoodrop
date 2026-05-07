import Foundation
import SwiftUI

enum QuestEvent {
    case animalDropped(name: String)
    case animalMerged(from: String, into: String, combo: Int, mode: GameMode)
    case scoreAchieved(Int)
    case dropSurvived
    case comboReached(Int)
    case rarityCreated(Rarity)
    case modePlayed(GameMode)
    case runFinished(mode: GameMode, score: Int, drops: Int, merges: Int)
    case tutorialStepCompleted(TutorialStep)
    case challengeCompleted(id: String, score: Int)
}

@MainActor
class QuestManager: ObservableObject {
    
    @Published var activeQuests: [Quest] = []
    
    private var questLibrary: [Quest] = []
    
    private let activeQuestsKey = "activeQuestsKey"
    private let lastQuestDateKey = "lastQuestDateKey"
    
    private let soundManager: SoundManager
    
    private let subscriptionManager: SubscriptionManager
    
    init(soundManager: SoundManager, subscriptionManager: SubscriptionManager) {
        self.soundManager = soundManager
        self.subscriptionManager = subscriptionManager
        buildQuestLibrary()
        loadQuests()
        selectDailyQuests()
    }
    
    func processEvent(type: QuestEvent) {
        for i in 0..<activeQuests.count {
            guard !activeQuests[i].isComplete else { continue }
            
            var quest = activeQuests[i]
            
            switch type {
            case .animalDropped(let name):
                if case .dropSpecificAnimal(let requiredName, _) = quest.type, name == requiredName {
                    quest.progress += 1
                }
            case .animalMerged(_, let newName, _, _):
                if case .dropSpecificAnimal(let requiredName, _) = quest.type, newName == requiredName {
                    quest.progress += 1
                }
            case .scoreAchieved(let score):
                if case .reachScore(_) = quest.type {
                    quest.progress = max(quest.progress, score)
                }
            case .dropSurvived:
                if case .surviveDrops(_) = quest.type {
                    quest.progress += 1
                }
            case .comboReached(let combo):
                if case .surviveDrops(_) = quest.type, combo >= 3 {
                    quest.progress += combo
                }
            case .rarityCreated(let rarity):
                if rarity == .legendary || rarity == .mythical,
                   case .surviveDrops(_) = quest.type {
                    quest.progress += 5
                }
            case .modePlayed(let mode):
                if mode == .dailySafari || mode == .challenge,
                   case .surviveDrops(_) = quest.type {
                    quest.progress += 1
                }
            case .runFinished(_, let score, let drops, let merges):
                switch quest.type {
                case .reachScore:
                    quest.progress = max(quest.progress, score)
                case .surviveDrops:
                    quest.progress += max(drops, merges)
                case .dropSpecificAnimal:
                    break
                }
            case .tutorialStepCompleted:
                if case .surviveDrops(_) = quest.type {
                    quest.progress += 1
                }
            case .challengeCompleted(_, let score):
                if case .reachScore(_) = quest.type {
                    quest.progress = max(quest.progress, score)
                }
            }
            
            if quest.goalReached && !quest.isComplete {
                quest.isComplete = true
                soundManager.playAchievementSound()
            }
            
            activeQuests[i] = quest
        }
        saveQuests()
    }
    
    func claimReward(for quest: Quest) {
        print("Player claimed \(quest.reward) Golden Eggs for completing '\(quest.title)'!")
        soundManager.playGoldenEggClaimedSound()
        
        subscriptionManager.goldenEggCount += quest.reward
        
        activeQuests.removeAll { $0.id == quest.id }
        saveQuests()
    }
    
    private func selectDailyQuests() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: lastQuestDateKey) as? Date ?? .distantPast
        
        if !calendar.isDateInToday(lastDate) || activeQuests.isEmpty {
            let incompleteQuests = activeQuests.filter { !$0.isComplete && $0.progress > 0 }
            let newQuestsNeeded = 3 - incompleteQuests.count
            
            if newQuestsNeeded > 0 {
                let currentQuestIDs = Set(activeQuests.map { $0.id })
                let newQuestPool = questLibrary.filter { !currentQuestIDs.contains($0.id) }
                
                let questsToAdd = Array(newQuestPool.shuffled().prefix(newQuestsNeeded))
                activeQuests = incompleteQuests + questsToAdd
                
                UserDefaults.standard.set(today, forKey: lastQuestDateKey)
                saveQuests()
            }
        }
    }
    
    private func saveQuests() {
        if let encodedQuests = try? JSONEncoder().encode(activeQuests) {
            UserDefaults.standard.set(encodedQuests, forKey: activeQuestsKey)
        }
    }
    
    private func loadQuests() {
        if let savedQuests = UserDefaults.standard.data(forKey: activeQuestsKey),
           let decodedQuests = try? JSONDecoder().decode([Quest].self, from: savedQuests) {
            activeQuests = decodedQuests
        }
    }
    
    private func buildQuestLibrary() {
        self.questLibrary = [
            Quest(id: "score_1k", title: "Novice Stacker", description: "Reach a score of 1,000 points.", type: .reachScore(1000), reward: 10),
            Quest(id: "drop_penguin_5", title: "Penguin Parade", description: "Drop 5 Penguins.", type: .dropSpecificAnimal(name: "Penguin", count: 5), reward: 12),
            Quest(id: "survive_20_drops", title: "Careful Keeper", description: "Make 20 drops in one day.", type: .surviveDrops(20), reward: 15),
            Quest(id: "score_5k", title: "Tower Tamer", description: "Reach a score of 5,000 points.", type: .reachScore(5000), reward: 25),
            Quest(id: "create_panda_2", title: "Panda Pair", description: "Create 2 Pandas from merges.", type: .dropSpecificAnimal(name: "Panda", count: 2), reward: 18),
            Quest(id: "create_lion_1", title: "Lion Keeper", description: "Create a Lion from merges.", type: .dropSpecificAnimal(name: "Lion", count: 1), reward: 30),
            Quest(id: "activity_50", title: "Safari Shift", description: "Build momentum through drops, combos, or special runs.", type: .surviveDrops(50), reward: 28),
            Quest(id: "score_10k", title: "Habitat Hero", description: "Reach a score of 10,000 points.", type: .reachScore(10000), reward: 45)
        ]
    }
}
