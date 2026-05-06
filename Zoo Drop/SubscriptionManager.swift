import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    
    @Published var isSubscribed: Bool = false
    @Published var goldenEggCount: Int = 0 {
        didSet { saveState() }
    }
    
    private(set) var lastClaimDate: Date?
    
    private let goldenEggsKey = "goldenEggCountKey"
    private let lastClaimDateKey = "lastClaimDateKey"
    private let isSubscribedKey = "isUserSubscribedKey"
    
    // --- MON-01 IMPLEMENTATION: PRODUCT IDs ---
    // The main subscription product ID.
    let subscriptionProductID = "com.yourcompany.zoodrop.zooclub.monthly"
    
    // The product IDs for consumable Golden Egg packs.
    let eggPackProductIDs: Set<String> = [
        "com.yourcompany.zoodrop.eggs.pack1", // e.g., 100 Eggs
        "com.yourcompany.zoodrop.eggs.pack2", // e.g., 550 Eggs
        "com.yourcompany.zoodrop.eggs.pack3"  // e.g., 1200 Eggs
    ]
    // --- END MON-01 IMPLEMENTATION ---

    private(set) var purchasedProductIDs = Set<String>()
    private var transactionUpdateListener: Task<Void, Never>? = nil

    var canClaimDailyGoldenEgg: Bool {
        guard isSubscribed else { return false }
        if let lastDate = lastClaimDate {
            return !Calendar.current.isDateInToday(lastDate)
        }
        return true
    }
    
    init() {
        loadState()
        
        transactionUpdateListener = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await updateSubscriptionStatus(for: transaction)
                    
                    // If it's a consumable, grant the reward.
                    if self.eggPackProductIDs.contains(transaction.productID) {
                        self.grantEggs(for: transaction.productID)
                    }
                    
                    await transaction.finish()
                }
            }
        }
        
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        transactionUpdateListener?.cancel()
    }

    func spendGoldenEgg(amount: Int) -> Bool {
        guard goldenEggCount >= amount else {
            print("❌ SubscriptionManager: Not enough Golden Eggs to spend.")
            return false
        }
        goldenEggCount -= amount
        return true
    }
    
    func claimDailyGoldenEgg() {
        guard canClaimDailyGoldenEgg else { return }
        goldenEggCount += 10
        lastClaimDate = Date()
        saveState()
        print("✅ SubscriptionManager: Daily reward claimed.")
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(goldenEggCount, forKey: goldenEggsKey)
        defaults.set(lastClaimDate, forKey: lastClaimDateKey)
        defaults.set(isSubscribed, forKey: isSubscribedKey)
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        goldenEggCount = defaults.integer(forKey: goldenEggsKey)
        lastClaimDate = defaults.object(forKey: lastClaimDateKey) as? Date
        isSubscribed = defaults.bool(forKey: isSubscribedKey)
    }
    
    // MARK: - StoreKit Logic
    
    func checkSubscriptionStatus() async {
        var validSubscription: Transaction?
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == self.subscriptionProductID && transaction.revocationDate == nil {
                    validSubscription = transaction
                }
            }
        }
        
        if let subscription = validSubscription {
            self.isSubscribed = true
            self.purchasedProductIDs.insert(subscription.productID)
        } else {
            self.isSubscribed = false
        }
        saveState()
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await updateSubscriptionStatus(for: transaction)
                
                // If it's a consumable, grant the reward immediately.
                if self.eggPackProductIDs.contains(transaction.productID) {
                    self.grantEggs(for: transaction.productID)
                }
                
                await transaction.finish()
            } else {
                throw NSError(domain: "com.yourcompany.zoodrop", code: 1001, userInfo: [NSLocalizedDescriptionKey: "StoreKit verification failed"])
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            print("❌ Could not sync with App Store to restore purchases: \(error)")
        }
    }
    
    private func updateSubscriptionStatus(for transaction: Transaction) async {
        if transaction.productID == self.subscriptionProductID && transaction.revocationDate == nil {
            self.isSubscribed = true
            self.purchasedProductIDs.insert(transaction.productID)
        }
        saveState()
    }
    
    // --- MON-01 IMPLEMENTATION: GRANT EGGS ---
    private func grantEggs(for productID: String) {
        switch productID {
        case "com.yourcompany.zoodrop.eggs.pack1":
            goldenEggCount += 100
            print("✅ Granted 100 Golden Eggs.")
        case "com.yourcompany.zoodrop.eggs.pack2":
            goldenEggCount += 550
            print("✅ Granted 550 Golden Eggs.")
        case "com.yourcompany.zoodrop.eggs.pack3":
            goldenEggCount += 1200
            print("✅ Granted 1200 Golden Eggs.")
        default:
            print("⚠️ Unknown consumable product purchased: \(productID)")
        }
    }
    // --- END MON-01 IMPLEMENTATION ---
}
