//
//  Meta.swift
//  MedicalConsult
//
//  Created by Roman Zoffoli on 23/03/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

class Meta {
    
    var createdAt: String
    var updatedAt: String = ""
    
    init(createdAt: String) {
        
        self.createdAt = createdAt
        
    }
    
}
