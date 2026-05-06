import SwiftUI
import StoreKit

struct ZooClubView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var soundManager: SoundManager
    
    // Holds subscription AND IAP products.
    @State private var subscriptionProduct: Product?
    @State private var iapProducts: [Product] = []
    
    @State private var isLoading = true
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var showConfetti = false
    @State private var showSubscribeConfetti = false
    @State private var bounce = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("background_sky").resizable().scaledToFill().ignoresSafeArea()
                Image("background_ground").resizable().scaledToFit().frame(height: 250)
                    .offset(y: 300).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("🎉 Join the Zoo Club!")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .padding(.top, 40)
                            .multilineTextAlignment(.center)

                        if isLoading {
                            ProgressView("Loading...")
                                .multilineTextAlignment(.center)
                        } else if let product = subscriptionProduct {
                            Text("Unlock exclusive perks for just \(product.displayPrice)/month:")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Image("golden_egg_closed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .shadow(color: .yellow.opacity(0.6), radius: 10, x: 0, y: 5)
                                .padding(.vertical, 8)
                                .rotationEffect(.degrees(subscriptionManager.isSubscribed ? 0 : 5))
                                // Animate rotation only when subscription status changes
                                .animation(subscriptionManager.isSubscribed ? .default : Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: subscriptionManager.isSubscribed)
                            
                            // Perks list with accessibility
                            perksList
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("Subscription perks list")
                            
                            subscriptionButton
                                .accessibilityAddTraits(subscriptionManager.isSubscribed ? .isSelected : [])
                                .accessibilityLabel(subscriptionManager.isSubscribed ? "Subscribed" : "Subscribe now")
                        } else {
                            Text("Subscription product not available.")
                                .multilineTextAlignment(.center)
                        }
                        
                        if subscriptionManager.isSubscribed && subscriptionManager.canClaimDailyGoldenEgg {
                            dailyRewardSection
                        }

                        if !iapProducts.isEmpty {
                            iapSection
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
                // Confetti overlay with smooth fade-out and non-blocking interaction
                if showConfetti || showSubscribeConfetti {
                    Image("confetti_burst")
                        .resizable()
                        .scaledToFit()
                        .frame(width: showSubscribeConfetti ? 250 : 200, height: showSubscribeConfetti ? 250 : 200)
                        .opacity(showConfetti || showSubscribeConfetti ? 1 : 0)
                        .animation(.easeOut(duration: 1), value: showConfetti || showSubscribeConfetti)
                        .allowsHitTesting(false) // Allow interactions to pass through
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showConfetti = false
                                    showSubscribeConfetti = false
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("Zoo Club")
            .alert(isPresented: $showingPurchaseAlert) {
                Alert(title: Text("Purchase"), message: Text(purchaseMessage), dismissButton: .default(Text("OK")))
            }
            // Load products and check subscription status when view appears
            .task {
                await loadProducts()
                await subscriptionManager.checkSubscriptionStatus()
            }
            .onAppear {
                if subscriptionManager.isSubscribed {
                    DispatchQueue.main.async {
                        soundManager.playEggOpenSound()
                    }
                }
            }
        }
    }

    // Extracted subscription button view for clarity
    private var subscriptionButton: some View {
        Button(action: {
            guard let product = subscriptionProduct else { return }
            Task { await purchase(product) }
        }) {
            Text(subscriptionManager.isSubscribed ? "Subscribed ✅" : "Subscribe Now")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: 250)
                .padding()
                .background(subscriptionManager.isSubscribed ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .scaleEffect(subscriptionManager.isSubscribed ? 1.0 : 1.05)
                .animation(.easeInOut(duration: 0.3), value: subscriptionManager.isSubscribed)
                .multilineTextAlignment(.center)
        }
        .disabled(subscriptionManager.isSubscribed)
    }

    // Perks list view with multiline text alignment
    var perksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            perkRow(icon: "crown.fill", text: "Exclusive Mythical Animals!", color: .yellow)
            perkRow(icon: "gift.fill", text: "Daily Golden Egg Bonus", color: .green)
            perkRow(icon: "nosign", text: "No Ads, Ever!", color: .red)
            perkRow(icon: "arrow.up.circle.fill", text: "Permanent +10% Score Bonus", color: .blue)
            perkRow(icon: "questionmark.diamond.fill", text: "Extra Daily Quest Slot", color: .purple)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func perkRow(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
    
    var dailyRewardSection: some View {
        ZStack {
            Image("goldenegg_open")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .scaleEffect(bounce ? 1.1 : 0.6)
                .shadow(color: .yellow.opacity(0.7), radius: 10)
            Image("sparklepoof")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .opacity(bounce ? 1 : 0)
                .animation(.easeOut(duration: 1.2), value: bounce)
        }
        .onAppear {
            bounce = true
            soundManager.playEggOpenSound()
        }
        .onTapGesture {
            withAnimation { showConfetti = true }
            subscriptionManager.claimDailyGoldenEgg()
            soundManager.playGoldenEggClaimedSound()
        }
        .padding(.top, 10)
        .transition(.scale)
    }
    
    var iapSection: some View {
        VStack {
            Text("Need a Boost?")
                .font(.title2.bold())
                .padding(.top)
                .multilineTextAlignment(.center)
            
            Text("Get more Golden Eggs to spend on power-ups!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ForEach(iapProducts) { product in
                Button(action: {
                    Task { await purchase(product) }
                }) {
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        Text(product.displayPrice)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange.gradient)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    // MARK: - StoreKit Functions
    func loadProducts() async {
        do {
            let allProductIDs = [subscriptionManager.subscriptionProductID] + subscriptionManager.eggPackProductIDs
            let products = try await Product.products(for: allProductIDs)
            
            // Separate the products into subscription and IAPs
            self.subscriptionProduct = products.first(where: { $0.id == subscriptionManager.subscriptionProductID })
            self.iapProducts = products.filter { subscriptionManager.eggPackProductIDs.contains($0.id) }
            
        } catch {
            print("❌ Failed to load products: \(error)")
        }
        isLoading = false
    }

    /// Handles purchasing of products including subscriptions and consumables.
    /// Displays appropriate success or error messages and triggers related animations and sounds.
    func purchase(_ product: Product) async {
        do {
            try await subscriptionManager.purchase(product)
            
            if product.type == .autoRenewable {
                purchaseMessage = "Thank you for subscribing to Zoo Club!"
                showSubscribeConfetti = true
                soundManager.playSubscribeSound()
            } else {
                purchaseMessage = "Purchase successful! Your Golden Eggs have been added."
                showConfetti = true
            }
            showingPurchaseAlert = true
            
        } catch {
            // Handle purchase errors gracefully
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
            showingPurchaseAlert = true
        }
    }
}
