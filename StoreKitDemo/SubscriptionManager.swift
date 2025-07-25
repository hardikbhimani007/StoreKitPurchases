//
//  SubscriptionManager.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit
import StoreKit

var isUserSubscribed = false

class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    private var products: [Product] = []
    
    // Product identifiers from your .storekit file
    private let productIds: Set<String> = [
        "com.prodev.app.StoreKitDemo.subscription.monthly",
        "com.prodev.app.StoreKitDemo.subscription.yearly"
    ]
    
    func fetchProducts() async throws -> [Product] {
        let storeProducts = try await Product.products(for: Array(productIds))
        
        if storeProducts.isEmpty {
            print("⚠️ No products returned from StoreKit!")
        } else {
            print("✅ StoreKit returned \(storeProducts.count) products.")
            for product in storeProducts {
                print("📦 Product: \(product.id) - \(product.displayName)")
            }
        }
        
        self.products = storeProducts.sorted(by: { $0.displayName < $1.displayName })
        return self.products
    }
    
    func product(for id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    func purchase(product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            print("✅ Purchase successful for: \(transaction.productID)")
            return transaction
        case .userCancelled:
            print("⚠️ Purchase cancelled by user")
            return nil
        case .pending:
            print("⏳ Purchase pending")
            return nil
        default:
            print("❌ Purchase failed: \(result)")
            return nil
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified(_, let error):
            throw error
        }
    }

    func checkSubscriptionStatus(for product: Product) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIds.contains(transaction.productID),
               transaction.revocationDate == nil {
                
                // ✅ Log offerID if redeemed via promo code
                if let offerID = transaction.offer?.id {
                    print("🟢 Active subscription: \(transaction.productID), redeemed with offerID: \(offerID)")
                } else {
                    print("🟢 Active subscription: \(transaction.productID), no promo offer ID")
                }
                
                // Optionally post a notification or update UI here
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)

                return true
            }
        }
        
        print("🔴 No active subscription found.")
        return false
    }
    
    func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIds.contains(transaction.productID),
                   transaction.revocationDate == nil,
                   transaction.expirationDate == nil || transaction.expirationDate! > Date() {
                    return true
                }
            }
        }
        return false
    }
    
    func purchaseWithPromotionalOffer(for product: Product, offerID: String) async throws -> Transaction? {
        guard let offer = product.subscription?.promotionalOffers.first(where: { $0.id == offerID }) else {
            throw NSError(domain: "OfferNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Promotional offer not found."])
        }

        // ⚠️ In .storekit testing, dummy values are OK
        let signatureData = "FAKE_SIGNATURE".data(using: .utf8)!
        
//        if let offerID = product.subscription?.promotionalOffers.first?.id{
////            _ = try await purchaseWithPromotionalOffer(for: product, offerID: offerID)
//        } else {
//            print("❌ Promotional offer not found")
//        }


//        let result = try await product.purchase(options: [
//            .promotionalOffer(
//                offerID: offer.id ?? "",
//                keyID: "1F156EB4",
//                nonce: UUID(),
//                signature: signatureData,
//                timestamp: Int(Date().timeIntervalSince1970)
//            )
//        ])
        
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction: Transaction = try checkVerified(verification)
            await transaction.finish()
            print("✅ Promo purchase successful for: \(transaction.productID)")
            return transaction
        case .userCancelled:
            print("⚠️ Promo purchase cancelled")
            return nil
        case .pending:
            print("⏳ Promo purchase pending")
            return nil
        default:
            print("❌ Promo purchase failed: \(result)")
            return nil
        }
    }
}
