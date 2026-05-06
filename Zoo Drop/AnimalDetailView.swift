import SwiftUI

struct AnimalDetailView: View {
    let animal: Animal
    let dismissAction: () -> Void // Closure to handle dismissal
    
    // State for the drag gesture
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            // Semi-transparent background that can be tapped to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissAction)

            // The main card view
            VStack(spacing: 0) {
                // --- 'X' BUTTON FOR DISMISSAL ---
                HStack {
                    Spacer()
                    Button(action: dismissAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding()

                // Animal content
                Image(animal.imageName)
                    .resizable().scaledToFit().frame(width: 150, height: 150)
                    .padding().background(animal.rarity.color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(animal.name).font(.largeTitle.bold()).padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rarity: \(animal.rarity.rawValue.capitalized)").font(.headline)
                    Text("Base Score: \(animal.scoreValue)").font(.headline)
                    if let ability = animal.ability {
                        Text("Special Ability: \(ability.description)").font(.headline)
                    }
                    if let result = animal.mergeResult {
                        Text("Merges into: \(result)").font(.headline)
                    } else {
                        Text("Final animal in the chain!").font(.headline)
                    }
                }
                .padding()
                
                Spacer()
            }
            .frame(maxWidth: 340, maxHeight: 500)
            .background(.thinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
            // --- GESTURE LOGIC ---
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { gesture in
                        // Dismiss if swiped down or right significantly
                        if gesture.translation.height > 100 || gesture.translation.width > 100 {
                            dismissAction()
                        } else {
                            // Snap back to center if not swiped far enough
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
        }
    }
}
