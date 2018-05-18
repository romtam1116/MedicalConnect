//
//  DataManager.swift
//  MedicalConsult
//
//  Created by Roman on 12/3/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Foundation

class DataManager {
    
    static let Instance = DataManager()
    
    var theLastTabIndex: Int = 0
    var postType: String = Constants.PostTypeDiagnosis
    var patientId: String = ""
    var patient: Patient? = nil
    var referringUserIds: [String] = []
    var referringUserMSP: String = ""
    var fromPatientProfile: Bool = false
    var recordDuration: Int = 0
    
    // MARK: Saved Tab Index
        
    func getLastTabIndex() -> Int {
        return self.theLastTabIndex
    }
    
    func setLastTabIndex(tabIndex: Int) {
        self.theLastTabIndex = tabIndex
    }
    
    // MARK: Post Type
    
    func getPostType() -> String {
        return self.postType
    }
    
    func setPostType(postType: String) {
        self.postType = postType
    }
    
    // MARK: Patient Id
    
    func getPatientId() -> String {
        return self.patientId
    }
    
    func setPatientId(patientId: String) {
        self.patientId = patientId
    }
    
    // MARK: Patient
    
    func getPatient() -> Patient? {
        return self.patient
    }
    
    func setPatient(patient: Patient?) {
        self.patient = patient
    }
    
    // MARK: Referring User IDs
    
    func getReferringUserIds() -> [String] {
        return self.referringUserIds
    }
    
    func setReferringUserIds(referringUserIds: [String]) {
        self.referringUserIds = referringUserIds
    }
    
    // MARK: Referring User MSP
    
    func getReferringUserMSP() -> String {
        return self.referringUserMSP
    }
    
    func setReferringUserMSP(referringUserMSP: String) {
        self.referringUserMSP = referringUserMSP
    }
    
    // MARK: From Patient Profile
    
    func getFromPatientProfile() -> Bool {
        return self.fromPatientProfile
    }
    
    func setFromPatientProfile(_ fromPatientProfile: Bool) {
        self.fromPatientProfile = fromPatientProfile
    }
    
    // MARK: Record Duration
    
    func getRecordDuration() -> Int {
        return self.recordDuration
    }
    
    func setRecordDuration(recordDuration: Int) {
        self.recordDuration = recordDuration
    }
    
}
