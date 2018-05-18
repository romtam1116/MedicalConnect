//
//  UserDefaultsUtil.swift
//  MedicalConsult
//
//  Created by Roman on 12/29/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class UserDefaultsUtil {

    class func SaveToken(_ token: String) {
        
        print("Save \(token)")
        
        UserService.Instance.configureInstance(token)
        
        KeychainService.savePassword(token: token as NSString)
        
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "token")
        defaults.synchronize()

    }
    
    class func LoadToken() -> String {
        if let token = KeychainService.loadPassword() as String? {
            return token
        } else {
            let defaults = UserDefaults.standard
            return defaults.object(forKey: "token") as? String ?? ""
        }
    }
    
    class func DeleteToken() {
        UserService.Instance.configureInstance("")
        KeychainService.savePassword(token: "" as NSString)
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "token")
        
    }
    
    class func SaveUserId(userid: String) {
        let defaults = UserDefaults.standard
        defaults.set(userid, forKey: "userid")
        defaults.synchronize()
    }
    
    class func LoadUserId() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "userid") as? String ?? ""
    }
    
    class func DeleteUserId() {
        UserDefaults.standard.removeObject(forKey: "userid")
    }
    
    class func SaveUserName(username: String) {
        let defaults = UserDefaults.standard
        defaults.set(username, forKey: "username")
        defaults.synchronize()
    }
    
    class func LoadUserName() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "username") as? String ?? ""
    }
    
    class func SavePassword(password: String) {
        let defaults = UserDefaults.standard
        defaults.set(password, forKey: "password")
        defaults.synchronize()
    }
    
    class func LoadPassword() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "password") as? String ?? ""
    }
    
    class func SaveForgotPasswordToken(token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "forgotPasswordToken")
        defaults.synchronize()
    }
    
    class func LoadForgotPasswordToken() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "forgotPasswordToken")
    }
    
    class func DeleteForgotPasswordToken() {
        UserDefaults.standard.removeObject(forKey: "forgotPasswordToken")
    }
    
    class func SaveLastNotificationID(id: String) {
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: "lastNotificationID")
        defaults.synchronize()
    }
    
    class func LoadLastNotificationID() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "lastNotificationID") as? String ?? ""
    }
    
    class func SaveMissedCalls(_ value: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: "missedCalls")
        defaults.synchronize()
    }
    
    class func LoadMissedCalls() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "missedCalls") as? String ?? ""
    }
    
    class func SaveFirstLoad(firstLoad: Int) {
        
        KeychainService.saveFirstLoad(firstLoad: "\(firstLoad)" as NSString)
        
    }
    
    class func LoadFirstLoad() -> Int {
        let firstLoad = KeychainService.loadFirstLoad() as String? ?? ""
        return firstLoad == "" ? 0 : Int(firstLoad)!
    }
    
}
