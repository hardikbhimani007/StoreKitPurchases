//
//  AppDelegate.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit
import StoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var transactionListenerTask: Task<Void, Never>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startTransactionListener()
        return true
    }
    
    private func startTransactionListener() {
        transactionListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self else { return }
                    let transaction = try SubscriptionManager.shared.checkVerified(result)
                    await transaction.finish()
                    
                    print("🔁 Updated transaction: \(transaction.productID)")
                    
                    if let revoked = transaction.revocationDate {
                        print("❌ Subscription was revoked on \(revoked)")
                    } else if let expiration = transaction.expirationDate, expiration <= Date() {
                        print("🔴 Subscription expired at \(expiration)")
                    } else {
                        print("✅ Subscription is still active")
                    }
                    
                    NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                    
                } catch {
                    print("❌ Failed to verify updated transaction: \(error)")
                }
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        transactionListenerTask?.cancel()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

