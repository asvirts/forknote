import Foundation
import ForknoteCore
import Observation
import StoreKit

public enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case userCancelled
    case failed(String)
}

@MainActor @Observable
public final class EntitlementManager {
    public private(set) var isPro: Bool
    public private(set) var proProduct: Product?
    public private(set) var isBusy = false
    public private(set) var lastError: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    public init() {
        isPro = UserDefaults.forknote.bool(forKey: SettingsKey.isProCached)
    }

    public var displayPrice: String {
        proProduct?.displayPrice ?? ForknoteConfig.proPriceFallback
    }

    public func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await verification in Transaction.updates {
                    guard let self else { return }
                    if case .verified(let transaction) = verification {
                        if transaction.productID == ForknoteConfig.proProductID {
                            self.setPro(transaction.revocationDate == nil)
                        }
                        await transaction.finish()
                    }
                }
            }
        }
        await refreshEntitlements()
        await loadProductIfNeeded()
    }

    public func loadProductIfNeeded() async {
        guard proProduct == nil else { return }
        do {
            let products = try await Product.products(for: [ForknoteConfig.proProductID])
            proProduct = products.first
        } catch {
            // Keep the fallback price until StoreKit can answer.
        }
    }

    public func refreshEntitlements() async {
        var unlocked = false
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification,
               transaction.productID == ForknoteConfig.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPro(unlocked)
    }

    @discardableResult
    public func purchase() async -> PurchaseOutcome {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        await loadProductIfNeeded()
        guard let product = proProduct else {
            let message = "Forknote Pro isn't available from the App Store right now."
            lastError = message
            return .failed(message)
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    setPro(true)
                    await transaction.finish()
                    return .purchased
                case .unverified(_, let error):
                    lastError = error.localizedDescription
                    return .failed(error.localizedDescription)
                }
            case .pending:
                return .pending
            case .userCancelled:
                return .userCancelled
            @unknown default:
                return .userCancelled
            }
        } catch {
            lastError = error.localizedDescription
            return .failed(error.localizedDescription)
        }
    }

    @discardableResult
    public func restore() async -> Bool {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return isPro
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func setPro(_ unlocked: Bool) {
        isPro = unlocked
        UserDefaults.forknote.set(unlocked, forKey: SettingsKey.isProCached)
    }
}
