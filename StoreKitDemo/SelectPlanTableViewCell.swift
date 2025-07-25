//
//  SelectPlanTableViewCell.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit
import StoreKit

class SelectPlanTableViewCell: UITableViewCell {
    
    @IBOutlet weak var contentVw: UIView!
    @IBOutlet weak var mainVw: UIView!
    @IBOutlet weak var activeVw: UIView!
    @IBOutlet weak var radioImg: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainVw.layer.borderColor = UIColor.systemBlue.cgColor
        mainVw.layer.borderWidth = 1
        mainVw.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configure(with product: Product, selected: Bool, isActive: Bool, disabled: Bool = false) {
        titleLbl.text = product.displayName
        subtitleLbl.text = product.displayPrice

        mainVw.layer.borderColor = selected ? UIColor.systemBlue.cgColor : UIColor.lightGray.cgColor
        mainVw.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.1) : UIColor.systemGray6
        
        radioImg.image = UIImage(systemName: selected ? "largecircle.fill.circle" : "circle")
        activeVw.isHidden = !isActive

        // Style if disabled
        if disabled {
            mainVw.alpha = 0.4
        } else {
            mainVw.alpha = 1.0
        }
    }
}
