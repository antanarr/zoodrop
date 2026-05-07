import SwiftUI

struct QuestsView: View {
    // Correctly subscribes to the QuestManager from the environment.
    @EnvironmentObject var questManager: QuestManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if questManager.activeQuests.isEmpty {
                    VStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Come back tomorrow for new quests!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    List {
                        // We iterate directly over the manager's published property.
                        ForEach(questManager.activeQuests) { quest in
                            // QuestRowView is now self-contained and receives its data.
                            QuestRowView(quest: quest)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Daily Quests")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct QuestRowView: View {
    // It now gets the shared manager instance from the environment, just like its parent.
    @EnvironmentObject var questManager: QuestManager
    let quest: Quest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quest.title)
                .font(.headline)
            
            Text(quest.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            let goal: Double = {
                switch quest.type {
                case .reachScore(let target), .dropSpecificAnimal(_, let target), .surviveDrops(let target):
                    return Double(target)
                }
            }()
            let progress = Double(quest.progress)
            
            ProgressView(value: progress, total: goal) {
                // Label inside the progress view for better accessibility.
                Text("\(Int(progress)) / \(Int(goal))")
            }
            .progressViewStyle(LinearProgressViewStyle(tint: quest.isComplete ? .green : .blue))
            
            if quest.isComplete {
                Button(action: {
                    questManager.claimReward(for: quest)
                }) {
                    Label("Claim Reward (\(quest.reward) 🥚)", systemImage: "gift.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    QuestsView()
        .environmentObject(QuestManager(soundManager: SoundManager(), subscriptionManager: SubscriptionManager()))
}
