//
//  StringUtil.swift
//  Drinkz
//
//  Created by Roman zoffoli on 02/08/15.
//  Copyright © 2016 Andres Bonilla. All rights reserved.
//

import Foundation

class StringUtil {
    
    static func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    static func isValidPassword(_ testStr:String) -> Bool {
        let passwordRegEx = "^(.{0,5}|[^A-Z]*|[^a-z]*|)$"
        
        let passwordTest = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return !passwordTest.evaluate(with: testStr)
    }
    
    static func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    static func formatPhoneNumber(numberString: String) -> String {
        var phoneNumber = numberString.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        let tempIndex = phoneNumber.startIndex
        
        if phoneNumber.count > 6 {
            let firstRange = tempIndex ..< phoneNumber.index(tempIndex, offsetBy: 3)
            let secondRange = phoneNumber.index(tempIndex, offsetBy: 3) ..< phoneNumber.index(tempIndex, offsetBy: 6)
            let thirdRange = phoneNumber.index(tempIndex, offsetBy: 6) ..< phoneNumber.endIndex
            phoneNumber = "\(phoneNumber[firstRange])-\(phoneNumber[secondRange])-\(phoneNumber[thirdRange])"
            
        } else if phoneNumber.count > 3 {
            let firstRange = tempIndex ..< phoneNumber.index(tempIndex, offsetBy: 3)
            let secondRange = phoneNumber.index(tempIndex, offsetBy: 3) ..< phoneNumber.endIndex
            phoneNumber = "\(phoneNumber[firstRange])-\(phoneNumber[secondRange])"
            
        }
        
        return phoneNumber
    }
}
