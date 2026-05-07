import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var availableProducts: [Product] = []
    @Published var isSubscribed = false {
        didSet { saveState() }
    }
    @Published private(set) var hasRemovedAds = false {
        didSet { saveState() }
    }
    @Published var goldenEggCount: Int = 0 {
        didSet { saveState() }
    }

    private(set) var lastClaimDate: Date?

    let monthlySubscriptionProductID = "com.yourskinmatters.zoodrop.zooclub.monthly"
    let yearlySubscriptionProductID = "com.yourskinmatters.zoodrop.zooclub.yearly"
    let removeAdsProductID = "com.yourskinmatters.zoodrop.removeads"
    let starterPackProductID = "com.yourskinmatters.zoodrop.starterpack"
    let subscriptionProductID = "com.yourskinmatters.zoodrop.zooclub.monthly"
    let subscriptionProductIDs: Set<String> = [
        "com.yourskinmatters.zoodrop.zooclub.monthly",
        "com.yourskinmatters.zoodrop.zooclub.yearly"
    ]
    let eggPackProductIDs: Set<String> = [
        "com.yourskinmatters.zoodrop.eggs.small",
        "com.yourskinmatters.zoodrop.eggs.medium",
        "com.yourskinmatters.zoodrop.eggs.large"
    ]
    let nonConsumableProductIDs: Set<String> = [
        "com.yourskinmatters.zoodrop.removeads"
    ]
    let consumableProductIDs: Set<String> = [
        "com.yourskinmatters.zoodrop.starterpack",
        "com.yourskinmatters.zoodrop.eggs.small",
        "com.yourskinmatters.zoodrop.eggs.medium",
        "com.yourskinmatters.zoodrop.eggs.large"
    ]

    private let goldenEggsKey = "goldenEggCountKey"
    private let lastClaimDateKey = "lastClaimDateKey"
    private let isSubscribedKey = "isUserSubscribedKey"
    private let hasRemovedAdsKey = "hasRemovedAdsKey"
    private let processedTransactionsKey = "processedStoreKitTransactionIDs"

    private(set) var purchasedProductIDs = Set<String>()
    private var processedTransactionIDs = Set<String>()
    private var transactionUpdateListener: Task<Void, Never>?

    var hasAdFreeEntitlement: Bool {
        isSubscribed || hasRemovedAds
    }

    var shouldShowAds: Bool {
        !hasAdFreeEntitlement
    }

    var canClaimDailyGoldenEgg: Bool {
        guard isSubscribed else { return false }
        if let lastClaimDate {
            return !Calendar.current.isDateInToday(lastClaimDate)
        }
        return true
    }

    init() {
        loadState()
        transactionUpdateListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        transactionUpdateListener?.cancel()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let productIDs = Array(subscriptionProductIDs.union(nonConsumableProductIDs).union(consumableProductIDs))
            availableProducts = try await Product.products(for: productIDs).sorted { lhs, rhs in
                productSortIndex(lhs.id) < productSortIndex(rhs.id)
            }
        } catch {
            print("SubscriptionManager: failed to load products: \(error.localizedDescription)")
            availableProducts = []
        }
    }

    func spendGoldenEgg(amount: Int) -> Bool {
        guard goldenEggCount >= amount else {
            print("SubscriptionManager: not enough Golden Eggs")
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
    }

    func checkSubscriptionStatus() async {
        var hasActiveSubscription = false
        var hasActiveRemoveAds = false
        purchasedProductIDs.removeAll()

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                print("SubscriptionManager: skipped unverified current entitlement")
                continue
            }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }

            purchasedProductIDs.insert(transaction.productID)
            if subscriptionProductIDs.contains(transaction.productID) {
                hasActiveSubscription = true
            } else if transaction.productID == removeAdsProductID {
                hasActiveRemoveAds = true
            }
        }

        isSubscribed = hasActiveSubscription
        hasRemovedAds = hasActiveRemoveAds
        saveState()
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw StorePurchaseError.verificationFailed
            }
            await handleVerifiedTransaction(transaction)
            await transaction.finish()
            return .success
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    @discardableResult
    func restore() async -> Bool {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            return true
        } catch {
            print("SubscriptionManager: restore failed: \(error.localizedDescription)")
            return false
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    print("SubscriptionManager: skipped unverified transaction update")
                    continue
                }
                await self.handleVerifiedTransaction(transaction)
                await transaction.finish()
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if subscriptionProductIDs.contains(transaction.productID) {
            if transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > Date() }) ?? true {
                isSubscribed = true
                purchasedProductIDs.insert(transaction.productID)
            } else {
                await checkSubscriptionStatus()
            }
            return
        }

        if transaction.productID == removeAdsProductID {
            if transaction.revocationDate == nil {
                hasRemovedAds = true
                purchasedProductIDs.insert(transaction.productID)
            } else {
                await checkSubscriptionStatus()
            }
            return
        }

        guard consumableProductIDs.contains(transaction.productID) else { return }
        let transactionKey = String(transaction.id)
        guard !processedTransactionIDs.contains(transactionKey) else {
            print("SubscriptionManager: transaction \(transaction.id) already granted")
            return
        }

        grantEggs(for: transaction.productID)
        processedTransactionIDs.insert(transactionKey)
        saveState()
    }

    private func grantEggs(for productID: String) {
        switch productID {
        case "com.yourskinmatters.zoodrop.starterpack":
            goldenEggCount += 250
        case "com.yourskinmatters.zoodrop.eggs.small":
            goldenEggCount += 100
        case "com.yourskinmatters.zoodrop.eggs.medium":
            goldenEggCount += 550
        case "com.yourskinmatters.zoodrop.eggs.large":
            goldenEggCount += 1200
        default:
            print("SubscriptionManager: unknown consumable product \(productID)")
        }
    }

    private func productSortIndex(_ productID: String) -> Int {
        switch productID {
        case monthlySubscriptionProductID:
            return 0
        case yearlySubscriptionProductID:
            return 1
        case removeAdsProductID:
            return 2
        case starterPackProductID:
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

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(goldenEggCount, forKey: goldenEggsKey)
        defaults.set(lastClaimDate, forKey: lastClaimDateKey)
        defaults.set(isSubscribed, forKey: isSubscribedKey)
        defaults.set(hasRemovedAds, forKey: hasRemovedAdsKey)
        defaults.set(Array(processedTransactionIDs), forKey: processedTransactionsKey)
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        goldenEggCount = defaults.integer(forKey: goldenEggsKey)
        lastClaimDate = defaults.object(forKey: lastClaimDateKey) as? Date
        isSubscribed = defaults.bool(forKey: isSubscribedKey)
        hasRemovedAds = defaults.bool(forKey: hasRemovedAdsKey)
        processedTransactionIDs = Set(defaults.stringArray(forKey: processedTransactionsKey) ?? [])
    }
}

enum StorePurchaseError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        "The App Store could not verify this purchase."
    }
}

enum PurchaseOutcome {
    case success
    case userCancelled
    case pending
}
