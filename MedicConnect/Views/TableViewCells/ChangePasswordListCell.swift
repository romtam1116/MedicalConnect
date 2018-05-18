//
//  ChangePasswordListCell.swift
//  MedicalConsult
//
//  Created by Roman on 12/25/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class ChangePasswordListCell: UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var txField: UITextField!
    
    func setCellWithTitle(title: String) {
        
        self.selectionStyle = UITableViewCellSelectionStyle.default
        
        self.lblTitle.text = title
        
    }
    
}
