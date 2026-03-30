import SwiftUI
import StoreKit

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var selectedPlan: SubscriptionPlan?
    @Published var errorMessage: String?
    @Published var isPurchasing = false

    enum ViewState {
        case idle, loading, loaded, error
    }

    let storeKitService = StoreKitService()

    var plans: [SubscriptionPlan] {
        SubscriptionPlan.plans
    }

    func load() async {
        state = .loading
        await storeKitService.loadProducts()
        selectedPlan = plans.first(where: { $0.badge == "Popular" })
        state = .loaded
    }

    func purchase() async {
        guard let plan = selectedPlan else { return }
        guard let product = storeKitService.products.first(where: { $0.id == plan.id }) else {
            // For free tier, no purchase needed
            return
        }

        isPurchasing = true
        do {
            _ = try await storeKitService.purchase(product)
            isPurchasing = false
        } catch {
            errorMessage = error.localizedDescription
            isPurchasing = false
        }
    }

    func restorePurchases() async {
        await storeKitService.restorePurchases()
    }
}
