import Foundation
import StoreKit

@MainActor
final class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscription: Product?
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let productIds = [
        "com.elite.dating.plus.monthly",
        "com.elite.dating.plus.yearly",
        "com.elite.dating.black.monthly",
        "com.elite.dating.black.yearly",
        "com.elite.dating.black.lifetime"
    ]

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.productIds)
                .sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products"
            isLoading = false
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await verifyWithServer(product: product, transactionId: String(transaction.id))
            await transaction.finish()
            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateCurrentEntitlements()
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updateCurrentEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func updateCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               let product = products.first(where: { $0.id == transaction.productID }) {
                purchasedSubscription = product
                return
            }
        }
        purchasedSubscription = nil
    }

    private func verifyWithServer(product: Product, transactionId: String) async {
        let body = SubscriptionVerifyRequest(
            productId: product.id,
            transactionId: transactionId
        )
        try? await APIClient.shared.requestVoid(.POST, path: "/api/v1/subscription/verify", body: body)
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "Purchase verification failed." }
    }
}

private struct SubscriptionVerifyRequest: Codable {
    let productId: String
    let transactionId: String
}
