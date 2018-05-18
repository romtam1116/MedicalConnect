//
//  RadAvatar.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class RadAvatar: UIImageView {
    
    let ColorOrange = UIColor(red: 244/255, green: 145/255, blue: 28/255, alpha: 1.0)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentMode = .scaleAspectFill
        
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        
        self.backgroundColor = UIColor.white //ColorOrange
        self.layer.cornerRadius = self.frame.height / 2
        
        self.layer.borderColor = UIColor.init(red: 116/255.0, green: 183/255.0, blue: 191/255.0, alpha: 1.0).cgColor
        self.layer.borderWidth = 1
    }
    
}
