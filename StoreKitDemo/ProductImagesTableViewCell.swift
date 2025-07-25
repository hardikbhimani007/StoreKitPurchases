//
//  ProductImagesTableViewCell.swift
//  StoreKitDemo
//
//  Created by DREAMWORLD on 21/07/25.
//

import UIKit

class ProductImagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconVw: UIView!
    @IBOutlet weak var iconImg: UIImageView!
    @IBOutlet weak var lockVw: UIView!
    @IBOutlet weak var lockImg: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
