//
//  SubscriptionViewController.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit
import StoreKit

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

class SubscriptionViewController: UIViewController {
    
    @IBOutlet weak var selectPlanTableVw: UITableView!
    
    var availablePlans: [Product] = []
    var selectedIndex: Int = 0
    var activeProductId: String?
    
    var isUserOnYearlyPlan: Bool {
        guard let activeId = activeProductId else { return false }
        return activeId.contains("yearly")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib()
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusUpdated), name: .subscriptionStatusChanged, object: nil)
        Task {
            await detectActivePlan()
            fetchAvailableSubscriptions()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()
            selectPlanTableVw.reloadData()
        }
    }
    
    @objc func subscriptionStatusUpdated() {
        Task {
            await detectActivePlan()
            let isActive = await SubscriptionManager.shared.hasActiveSubscription()
            isUserSubscribed = isActive
            
            await MainActor.run {
                if isActive, let activeId = activeProductId,
                   let index = availablePlans.firstIndex(where: { $0.id == activeId }) {
                    selectedIndex = index
                } else if let defaultIndex = availablePlans.firstIndex(where: { $0.id.contains("monthly") }) {
                    // No active plan — reset to default UI
                    activeProductId = nil
                    selectedIndex = defaultIndex
                }

                selectPlanTableVw.reloadData()
            }
        }
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func registerNib() {
        let nib = UINib(nibName: "SelectPlanTableViewCell", bundle: nil)
        selectPlanTableVw.register(nib, forCellReuseIdentifier: "SelectPlanTableViewCell")
    }
    
    func detectActivePlan() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil,
                   transaction.expirationDate == nil || transaction.expirationDate! > Date() {
                    activeProductId = transaction.productID
                    break
                }
            }
        }
    }
    
    func fetchAvailableSubscriptions() {
        Task {
            do {
                let products = try await SubscriptionManager.shared.fetchProducts()
                self.availablePlans = products
                
                // Auto-select: Active plan or fallback to monthly
                if let activeId = activeProductId,
                   let index = availablePlans.firstIndex(where: { $0.id == activeId }) {
                    selectedIndex = index
                } else if let index = availablePlans.firstIndex(where: { $0.id.contains("monthly") }) {
                    selectedIndex = index
                }
                
                DispatchQueue.main.async {
                    self.selectPlanTableVw.reloadData()
                }
                
            } catch {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func checkActiveSubscription() async {
        let isActive = await SubscriptionManager.shared.hasActiveSubscription()
        DispatchQueue.main.async {
            if isActive {
                self.showAlert(title: "Subscription Active", message: "You have an active subscription.")
            } else {
                self.showAlert(title: "No Active Subscription", message: "No active subscription found.")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func requestRefundBtnTap(_ sender: UIButton) {
        guard selectedIndex < availablePlans.count else {
               showAlert(title: "No Plan Selected", message: "Please select a subscription plan.")
               return
           }

           let selectedProduct = availablePlans[selectedIndex]
           let productID = selectedProduct.id

           guard let windowScene = self.view.window?.windowScene else {
               showAlert(title: "Error", message: "Unable to find active window scene.")
               return
           }

           Task {
               do {
                   var matchingTransaction: Transaction?

                   // Find the active transaction for the selected product
                   for await result in Transaction.currentEntitlements {
                       if case .verified(let transaction) = result,
                          transaction.productID == productID,
                          transaction.revocationDate == nil,
                          transaction.expirationDate == nil || transaction.expirationDate! > Date() {
                           matchingTransaction = transaction
                           break
                       }
                   }

                   guard let transaction = matchingTransaction else {
                       showAlert(title: "No Transaction", message: "No active transaction found for this product.")
                       return
                   }

                   let status = try await Transaction.beginRefundRequest(for: transaction.id, in: windowScene)

                   switch status {
                   case .userCancelled:
                       showAlert(title: "Cancelled", message: "You cancelled the refund request.")
                   case .success:
                       showAlert(title: "Success", message: "Refund request submitted successfully.")
                   @unknown default:
                       showAlert(title: "Unknown", message: "An unknown refund result occurred.")
                   }
               } catch {
                   showAlert(title: "Error", message: error.localizedDescription)
               }
           }
    }
    
    @IBAction func restorePurchaseBtnTap(_ sender: UIButton) {
        Task {
            do {
                // Sync transactions with StoreKit
                try await AppStore.sync()
                showAlert(title: "Restore Completed", message: "Your purchases have been restored.")
                await checkActiveSubscription()
            } catch {
                showAlert(title: "Restore Failed", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func promoOfferBtnTap(_ sender: UIButton) {
        guard selectedIndex < availablePlans.count else {
                 showAlert(title: "Select a Plan", message: "Please select a plan to continue.")
                 return
             }

             let selectedProduct = availablePlans[selectedIndex]
             let offerID = selectedProduct.id.contains("yearly") ? "PROMO50Y" : "PROMO50M"

             Task {
                 do {
                     let transaction = try await SubscriptionManager.shared.purchaseWithPromotionalOffer(for: selectedProduct, offerID: offerID)
                     if transaction != nil {
                         isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()
                         NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                         showAlert(title: "Subscribed", message: "Promo offer applied successfully.")
                         await detectActivePlan()
                         fetchAvailableSubscriptions()
                         self.dismiss(animated: true)
                     }
                 } catch {
                     showAlert(title: "Promo Failed", message: error.localizedDescription)
                 }
             }
    }
    
    @IBAction func redeemCodeBtnTap(_ sender: UIButton) {
        if #available(iOS 16.0, *) {
            guard let windowScene = self.view.window?.windowScene else {
                debugPrint("Offer Code Sheet: No windowScene found.")
                return
            }
            Task {
                do {
                    try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                    debugPrint("Offer Code Sheet: Presented (StoreKit 2).")
                } catch {
                    debugPrint("Offer Code Sheet: Failed with error \(error).")
                }
            }
        } else if #available(iOS 14.0, *) {
            SKPaymentQueue.default().presentCodeRedemptionSheet()
            debugPrint("Offer Code Sheet: Presented (StoreKit 1).")
        } else {
            showAlert(title: "Unavailable", message: "Offer code redemption requires iOS 14+.")
        }
    }
    
    @IBAction func subscribeNowBtnTap(_ sender: UIButton) {
        guard selectedIndex < availablePlans.count else {
            showAlert(title: "No Plan Selected", message: "Please select a subscription plan.")
            return
        }

        let selectedProduct = availablePlans[selectedIndex]

        Task {
            do {
                let transaction = try await SubscriptionManager.shared.purchase(product: selectedProduct)
                if transaction != nil {
                    // Optionally handle post-purchase success
                    isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()

                    NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                    NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusUpdated), name: .subscriptionStatusChanged, object: nil)

                    showAlert(title: "Success", message: "You are now subscribed!")
                    await detectActivePlan()
                    fetchAvailableSubscriptions()
                    self.dismiss(animated: true)
                }
            } catch {
                showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func manageSubscriptionBtnTap(_ sender: UIButton) {
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared
                .connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                
                Task {
                    do {
                        try await AppStore.showManageSubscriptions(in: windowScene)
                    } catch {
                        showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            } else {
                showAlert(title: "Unavailable", message: "No active window scene available.")
            }
        } else {
            showAlert(title: "Unavailable", message: "Offer code redemption requires iOS 16+.")
        }
    }
    
    @IBAction func closeBtnTap(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension SubscriptionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availablePlans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectPlanTableViewCell", for: indexPath) as? SelectPlanTableViewCell
        let product = availablePlans[indexPath.row]

        let isSelected = indexPath.row == selectedIndex
        let isActive = product.id == activeProductId
        let isDisabled = isUserOnYearlyPlan && product.id.contains("monthly")

        cell?.configure(with: product, selected: isSelected, isActive: isActive, disabled: isDisabled)
        cell?.isUserInteractionEnabled = !isDisabled
        cell?.contentView.alpha = isDisabled ? 0.4 : 1.0

        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let product = availablePlans[indexPath.row]
        
        // Prevent downgrade from yearly to monthly
        if isUserOnYearlyPlan && product.id.contains("monthly") {
            showAlert(title: "Not Allowed", message: "You are already subscribed to the yearly plan.")
            return
        }
        
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}
