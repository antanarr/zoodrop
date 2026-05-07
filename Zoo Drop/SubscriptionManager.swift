import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var availableProducts: [Product] = []
    @Published var isSubscribed = false {
        didSet { saveState() }
    }
    @Published var goldenEggCount: Int = 0 {
        didSet { saveState() }
    }

    private(set) var lastClaimDate: Date?

    let subscriptionProductID = "com.yourskinmatters.zoodrop.zooclub.monthly"
    let eggPackProductIDs: Set<String> = [
        "com.yourskinmatters.zoodrop.eggs.small",
        "com.yourskinmatters.zoodrop.eggs.medium",
        "com.yourskinmatters.zoodrop.eggs.large"
    ]

    private let goldenEggsKey = "goldenEggCountKey"
    private let lastClaimDateKey = "lastClaimDateKey"
    private let isSubscribedKey = "isUserSubscribedKey"
    private let processedTransactionsKey = "processedStoreKitTransactionIDs"

    private(set) var purchasedProductIDs = Set<String>()
    private var processedTransactionIDs = Set<String>()
    private var transactionUpdateListener: Task<Void, Never>?

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
            let productIDs = [subscriptionProductID] + Array(eggPackProductIDs)
            availableProducts = try await Product.products(for: productIDs).sorted { lhs, rhs in
                lhs.displayName < rhs.displayName
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
        purchasedProductIDs.removeAll()

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }

            purchasedProductIDs.insert(transaction.productID)
            if transaction.productID == subscriptionProductID {
                hasActiveSubscription = true
            }
        }

        isSubscribed = hasActiveSubscription
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

    func restore() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("SubscriptionManager: restore failed: \(error.localizedDescription)")
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.handleVerifiedTransaction(transaction)
                await transaction.finish()
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productID == subscriptionProductID {
            if transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > Date() }) ?? true {
                isSubscribed = true
                purchasedProductIDs.insert(transaction.productID)
            } else {
                await checkSubscriptionStatus()
            }
            return
        }

        guard eggPackProductIDs.contains(transaction.productID) else { return }
        let transactionKey = String(transaction.id)
        guard !processedTransactionIDs.contains(transactionKey) else { return }

        grantEggs(for: transaction.productID)
        processedTransactionIDs.insert(transactionKey)
        saveState()
    }

    private func grantEggs(for productID: String) {
        switch productID {
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

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(goldenEggCount, forKey: goldenEggsKey)
        defaults.set(lastClaimDate, forKey: lastClaimDateKey)
        defaults.set(isSubscribed, forKey: isSubscribedKey)
        defaults.set(Array(processedTransactionIDs), forKey: processedTransactionsKey)
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        goldenEggCount = defaults.integer(forKey: goldenEggsKey)
        lastClaimDate = defaults.object(forKey: lastClaimDateKey) as? Date
        isSubscribed = defaults.bool(forKey: isSubscribedKey)
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
