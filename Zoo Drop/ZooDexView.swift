import SwiftUI

struct ZooDexView: View {
    @EnvironmentObject var zooDexManager: ZooDexManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedAnimal: Animal?
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]

    var body: some View {
        // ZStack allows us to overlay the custom detail view
        ZStack {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Looping over 'allAnimals' to show every defined animal
                        ForEach(AnimalLibrary.allAnimals) { animal in
                            Button(action: {
                                if zooDexManager.isUnlocked(animal) {
                                    // Animate the appearance of the detail view
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedAnimal = animal
                                    }
                                }
                            }) {
                                ZooDexGridItemView(animal: animal)
                                    .environmentObject(zooDexManager)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .navigationTitle("ZooDex")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .blur(radius: selectedAnimal != nil ? 3 : 0) // Blur background when detail view is shown

            // --- CUSTOM MODAL PRESENTATION ---
            if let animal = selectedAnimal {
                AnimalDetailView(animal: animal, dismissAction: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedAnimal = nil
                    }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
