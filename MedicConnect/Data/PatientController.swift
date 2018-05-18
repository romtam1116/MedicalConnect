//
//  PatientController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-29.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

class PatientController {
    
    static let Instance = PatientController()
    
    fileprivate var patients: [Patient] = []
    
    //MARK: Patients
    
    func getPatients() -> [Patient] {
        return self.patients
    }
    
    func setPatients(_ patients: [Patient]) {
        self.patients = patients
    }
    
    func findPatientById(_ id: String) -> Patient? {
        if id == "" {
            return nil
        }
        
        for index in 0..<self.patients.count {
            if id == self.patients[index].id {
                return self.patients[index]
            }
        }
        
        return nil
    }
    
}
