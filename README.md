# StoreKitPurchases

🚀 A sample iOS app demonstrating how to implement **auto-renewable subscriptions** using **StoreKit 2**, built with **UIKit** and tested locally using `.storekit` configuration files.

---

## 🔍 Project Overview

This app allows users to unlock premium features using subscription plans (Monthly/Yearly). It integrates:

- Offer Codes
- Promotional Offers
- Subscription Restoration
- Local StoreKit testing

Built using **UIKit** and **StoreKit 2**, it simulates the full subscription lifecycle without needing App Store Connect.

---

## 🛠️ Tools & Technologies Used

- ✅ **Language**: Swift 6
- ✅ **UI Framework**: UIKit + Storyboards
- ✅ **StoreKit Framework**: StoreKit 2
- ✅ **Testing**: iOS Simulator (iOS 18+)
- ✅ **StoreKit Config**: Local `.storekit` file for offers, plans, and promo testing

---

## 💡 UIKit Concepts Used

- `UITableView` for subscription plan selection
- Storyboard-based UI and `@IBAction`/`@IBOutlet` connections
- `UIViewController` lifecycle for screen transitions
- Dynamic table updates for active subscriptions
- Custom table view cells for plan display

---

## 🧱 StoreKit 2 Concepts Implemented

- `Product` and `Transaction` API
- `.currentEntitlements` for checking active subscriptions
- `AppStore.presentOfferCodeRedeemSheet` for redeeming offer codes
- Displaying available promotional offers in real-time

---

## 🧭 App Workflow

### 1. 🔓 Unlock Premium Content
- Users select plans from a local `.storekit` file.
- Subscribing unlocks paid product content.
  
### 2. 🗂 Manage Subscriptions
- View current plan
- Switch plans (e.g., Monthly → Yearly)
- Cancel from native Manage Subscription screen

### 3. 🏷 Redeem Offer Codes
- Redeem codes via StoreKit 2's native redemption sheet
- Apply discounts or free trials instantly

### 4. 💰 Promotional Offers
- 7-day free trial
- Discounted pricing shown if available

### 5. 🔄 Restore Purchases
- Restore subscriptions on reinstall or device change
- Real-time entitlement sync

---

## 🔥 Features

- Auto-renewable subscriptions
- Offer code redemption
- Introductory & promotional offers
- Refund and subscription management support
- No App Store Connect required for testing

---

## 🔮 Future Scope

- 🔐 Integrate real App Store Connect validation
- 📊 Add offer code usage analytics
- 🌍 Add localization & regional pricing
- 🧠 AI for smart plan recommendations
- ☁ Sync subscription state with Firebase or CloudKit
- 🎨 SwiftUI hybrid UI

---

## 📂 Creating & Using `.storekit` Files

- Add `.storekit` from File > New > StoreKit Config File
- Define subscription groups, plans, intro offers, and promo codes
- Simulate permission prompts, refunds, cancellations, etc.

---

## 📲 App UI Usage

- 🔓 Tap "Unlock Now" → Choose plan → Subscribe
- 🏷 Redeem offers → Apply codes via sheet
- 💰 Promo button → View available deals
- 🔄 Restore button → Restore active plans
- 💸 Refund button → Request refund
- ⚙ Manage button → Go to iOS Manage Subscription screen

---

## 🎉 After Subscription

You’ll unlock all premium items instantly. The StoreKit Transaction panel in Xcode helps test permissions, offers, expiration, and refunds.

---

Happy Coding! 🧑‍💻📱  
