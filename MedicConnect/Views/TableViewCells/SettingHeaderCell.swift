//
//  SettingHeaderCell.swift
//  MedicalConsult
//
//  Created by Roman on 12/22/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class SettingHeaderCell: UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    
    func setTitle(title: String) {
        
        self.lblTitle.text = title
        
    }

}
