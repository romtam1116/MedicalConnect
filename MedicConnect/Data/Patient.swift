//
//  Patient.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-29.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

class Patient {
    
    var id: String
    var name: String
    var patientNumber: String
    var birthdate: String
    var phoneNumber: String
    var address: String
    var user: User
    var meta: Meta
    
    init(id: String, name: String, patientNumber: String, birthdate: String, phoneNumber: String, address: String, meta: Meta, user: User) {
        
        self.id = id
        self.name = name
        self.patientNumber = patientNumber
        self.birthdate = birthdate
        self.phoneNumber = phoneNumber
        self.address = address
        self.meta = meta
        self.user = user
        
    }
    
    func getFormattedDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.meta.createdAt) as Date
        let formattedDate = DateUtil.GetBirthDate(dDate) as String? ?? ""
        
        return formattedDate
        
    }
    
    func getFormattedBirthDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.birthdate) as Date
        let formattedDate = DateUtil.GetBirthDate(dDate) as String? ?? ""
        
        return formattedDate
        
    }
}
