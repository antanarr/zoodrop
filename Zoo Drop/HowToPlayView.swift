import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Section(header: Text("The Goal").font(.title2.bold())) {
                        Text("Stack animals as high as you can without them crossing the line at the top. Merge identical animals to evolve them into bigger ones and score points!")
                    }
                    
                    Section(header: Text("Controls").font(.title2.bold())) {
                        Text("1. **Drag** your finger left and right to aim.\n2. **Lift** your finger to drop the animal.")
                    }
                    
                    Section(header: Text("Pro Tips").font(.title2.bold())) {
                        Text("• **Plan Ahead:** Use the 'Next Animal' display to plan your moves.\n• **Build a Foundation:** Heavy, flat animals make a stable base.\n• **Master the Merge:** Setting up chain-reaction merges is the key to a huge score!")
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
