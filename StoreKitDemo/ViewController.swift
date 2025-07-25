//
//  ViewController.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var iconsTableVw: UITableView!
    @IBOutlet weak var subscribeNowBtn: UIButton!
    
    let iconNames = [
        "icon1", "icon2", "icon3", "icon4", "icon5",
        "icon6", "icon7", "icon8", "icon9", "icon10",
        "icon11", "icon12", "icon13", "icon14", "icon15",
        "icon16", "icon17", "icon18", "icon19", "icon20",
        "icon21", "icon22", "icon23", "icon24"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nibRegister()
        iconsTableVw.delegate = self
        iconsTableVw.dataSource = self
        subscribeNowBtn.layer.cornerRadius = 16
        iconsTableVw.layer.cornerRadius = 16
        
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionUpdated), name: .subscriptionStatusChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()
            iconsTableVw.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()
            iconsTableVw.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func subscriptionUpdated() {
        Task {
            isUserSubscribed = await SubscriptionManager.shared.hasActiveSubscription()
            iconsTableVw.reloadData()
        }
    }
    
    private func nibRegister() {
        let nib = UINib(nibName: "ProductImagesTableViewCell", bundle: nil)
        iconsTableVw.register(nib, forCellReuseIdentifier: "ProductImagesTableViewCell")
    }
    
    @IBAction func subscribeNowBtnTap(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let subscriptionVC = sb.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController
        present(subscriptionVC!, animated: true)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iconNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductImagesTableViewCell", for: indexPath) as? ProductImagesTableViewCell else {
            return UITableViewCell()
        }
        
        let iconName = iconNames[indexPath.row]
        cell.iconImg.image = UIImage(named: iconName)
        cell.lockVw.isHidden = isUserSubscribed || indexPath.row <= 2
        return cell
    }
}
