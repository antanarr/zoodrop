import SwiftUI
import StoreKit

struct ZooClubView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var soundManager: SoundManager

    @State private var subscriptionProducts: [Product] = []
    @State private var removeAdsProduct: Product?
    @State private var consumableProducts: [Product] = []
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var showConfetti = false
    @State private var bounce = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("background_sky")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Image("background_ground")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .offset(y: 300)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header

                        if isLoading {
                            ProgressView("Loading purchases...")
                                .padding(.vertical, 40)
                        } else {
                            membershipSection
                            removeAdsSection
                            consumablesSection
                            legalAndRestoreSection
                        }

                        if subscriptionManager.isSubscribed && subscriptionManager.canClaimDailyGoldenEgg {
                            dailyRewardSection
                        }
                    }
                    .padding()
                }

                if showConfetti {
                    Image("confetti_burst")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .transition(.opacity.combined(with: .scale))
                        .allowsHitTesting(false)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                withAnimation {
                                    showConfetti = false
                                }
                            }
                        }
                }
            }
            .navigationTitle("Zoo Club")
            .alert(isPresented: $showingPurchaseAlert) {
                Alert(title: Text("Purchase"), message: Text(purchaseMessage), dismissButton: .default(Text("OK")))
            }
            .task {
                await loadProducts()
                await subscriptionManager.checkSubscriptionStatus()
            }
            .onAppear {
                if subscriptionManager.isSubscribed {
                    soundManager.playEggOpenSound()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("zooclubanimallogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)

            Text("Zoo Club")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)

            Text("Choose a subscription, remove ads forever, or stock up on Golden Eggs.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.top, 26)
    }

    private var membershipSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Zoo Club Membership", icon: "crown.fill", color: .yellow)

            Text("Monthly and yearly plans include all Zoo Club perks while your subscription is active.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                perkRow(icon: "nosign", text: "Ad-free play and revives while subscribed", color: .red)
                perkRow(icon: "gift.fill", text: "Daily Golden Egg claim", color: .green)
                perkRow(icon: "sparkles", text: "Subscriber-only animals and rewards", color: .purple)
                perkRow(icon: "arrow.clockwise.circle.fill", text: "Revive without watching rewarded ads", color: .blue)
            }
            .padding(.vertical, 4)

            if subscriptionProducts.isEmpty {
                unavailableText("Zoo Club plans are not available right now.")
            } else {
                ForEach(subscriptionProducts) { product in
                    productCard(
                        product: product,
                        badge: product.id == subscriptionManager.yearlySubscriptionProductID ? "Best value" : "Flexible",
                        detail: subscriptionDetail(for: product),
                        isOwned: subscriptionManager.isSubscribed,
                        actionTitle: subscriptionManager.isSubscribed ? "Active" : "Subscribe"
                    )
                }
            }
        }
        .modifier(PremiumPanel())
    }

    @ViewBuilder
    private var removeAdsSection: some View {
        if let product = removeAdsProduct {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Remove Ads", icon: "shield.checkered", color: .teal)

                Text("A one-time purchase that removes interstitial and rewarded ads. Ad-free revive rewards are granted without an ad.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                productCard(
                    product: product,
                    badge: "One-time",
                    detail: "Permanent ad-free play and revives",
                    isOwned: subscriptionManager.hasRemovedAds,
                    actionTitle: subscriptionManager.hasRemovedAds ? "Owned" : "Remove Ads"
                )
            }
            .modifier(PremiumPanel())
        }
    }

    @ViewBuilder
    private var consumablesSection: some View {
        if !consumableProducts.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Golden Eggs", icon: "circle.fill", color: .orange)

                Text("Consumable packs add Golden Eggs to this device after the App Store verifies the transaction.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(consumableProducts) { product in
                    productCard(
                        product: product,
                        badge: consumableBadge(for: product),
                        detail: consumableDetail(for: product),
                        isOwned: false,
                        actionTitle: "Buy"
                    )
                }
            }
            .modifier(PremiumPanel())
        }
    }

    private var dailyRewardSection: some View {
        VStack(spacing: 8) {
            Text("Daily Zoo Club Claim")
                .font(.headline)

            ZStack {
                Image("goldenegg_open")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
                    .scaleEffect(bounce ? 1.08 : 0.72)
                    .shadow(color: .yellow.opacity(0.7), radius: 10)

                Image("sparklepoof")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
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

            Text("Tap to claim 10 Golden Eggs.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var legalAndRestoreSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing)

            Text("Subscriptions renew automatically until cancelled in App Store settings. Remove Ads is non-consumable and restorable. Golden Egg packs and Starter Pack are consumables.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                NavigationLink("Privacy") { PrivacyPolicyView() }
                Text("|")
                NavigationLink("Terms") { TermsOfUseView() }
                Text("|")
                NavigationLink("Subscription") { SubscriptionTermsView() }
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal)
    }

    private func productCard(
        product: Product,
        badge: String,
        detail: String,
        isOwned: Bool,
        actionTitle: String
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(badge)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.08))
                        .clipShape(Capsule())
                }

                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                Task { await purchase(product) }
            } label: {
                VStack(spacing: 2) {
                    Text(isOwned ? actionTitle : product.displayPrice)
                        .font(.headline)
                    if !isOwned {
                        Text(actionTitle)
                            .font(.caption.weight(.semibold))
                    }
                }
                .frame(width: 96)
                .frame(minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(isOwned ? .green : .blue)
            .disabled(isOwned || isPurchasing)
        }
        .padding()
        .background(Color.white.opacity(0.72))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private func sectionTitle(_ text: String, icon: String, color: Color) -> some View {
        Label {
            Text(text)
                .font(.title3.bold())
        } icon: {
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }

    private func perkRow(icon: String, text: String, color: Color) -> some View {
        Label {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        } icon: {
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }

    private func unavailableText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.55))
            .cornerRadius(12)
    }

    private func subscriptionDetail(for product: Product) -> String {
        if product.id == subscriptionManager.yearlySubscriptionProductID {
            return "Billed yearly. Includes all active Zoo Club benefits."
        }

        return "Billed monthly. Cancel anytime in App Store settings."
    }

    private func consumableBadge(for product: Product) -> String {
        product.id == subscriptionManager.starterPackProductID ? "Starter" : "Egg pack"
    }

    private func consumableDetail(for product: Product) -> String {
        switch product.id {
        case subscriptionManager.starterPackProductID:
            return "Adds 250 Golden Eggs."
        case "com.yourskinmatters.zoodrop.eggs.small":
            return "Adds 100 Golden Eggs."
        case "com.yourskinmatters.zoodrop.eggs.medium":
            return "Adds 550 Golden Eggs."
        case "com.yourskinmatters.zoodrop.eggs.large":
            return "Adds 1200 Golden Eggs."
        default:
            return "Adds Golden Eggs."
        }
    }

    private func loadProducts() async {
        await subscriptionManager.loadProducts()
        await MainActor.run {
            let products = subscriptionManager.availableProducts
            subscriptionProducts = products
                .filter { subscriptionManager.subscriptionProductIDs.contains($0.id) }
                .sorted { productSortIndex($0.id) < productSortIndex($1.id) }
            removeAdsProduct = products.first { $0.id == subscriptionManager.removeAdsProductID }
            consumableProducts = products
                .filter { subscriptionManager.consumableProductIDs.contains($0.id) }
                .sorted { productSortIndex($0.id) < productSortIndex($1.id) }
            isLoading = false
        }
    }

    private func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let outcome = try await subscriptionManager.purchase(product)

            switch outcome {
            case .success:
                handlePurchaseSuccess(for: product)
            case .pending:
                purchaseMessage = "Purchase pending. The App Store will finish it after approval or payment completes."
                showingPurchaseAlert = true
            case .userCancelled:
                return
            }
        } catch {
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
            showingPurchaseAlert = true
        }
    }

    private func handlePurchaseSuccess(for product: Product) {
        if subscriptionManager.subscriptionProductIDs.contains(product.id) {
            purchaseMessage = "Zoo Club is active. Thanks for subscribing."
            soundManager.playSubscribeSound()
        } else if product.id == subscriptionManager.removeAdsProductID {
            purchaseMessage = "Ads removed. This purchase can be restored on your Apple devices."
            soundManager.playSubscribeSound()
        } else {
            purchaseMessage = "Purchase successful. Your Golden Eggs have been added."
            soundManager.playGoldenEggClaimedSound()
        }

        withAnimation { showConfetti = true }
        showingPurchaseAlert = true
    }

    private func restorePurchases() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        let didRestore = await subscriptionManager.restore()
        purchaseMessage = didRestore
            ? "Restore complete. Eligible subscriptions and Remove Ads purchases are active."
            : "Restore failed. Please try again from a reliable connection."
        showingPurchaseAlert = true
    }

    private func productSortIndex(_ productID: String) -> Int {
        switch productID {
        case subscriptionManager.monthlySubscriptionProductID:
            return 0
        case subscriptionManager.yearlySubscriptionProductID:
            return 1
        case subscriptionManager.removeAdsProductID:
            return 2
        case subscriptionManager.starterPackProductID:
            return 3
        case "com.yourskinmatters.zoodrop.eggs.small":
            return 4
        case "com.yourskinmatters.zoodrop.eggs.medium":
            return 5
        case "com.yourskinmatters.zoodrop.eggs.large":
            return 6
        default:
            return 99
        }
    }
}

private struct PremiumPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}
