//
//  DateUtil.swift
//  Shamar
//
//  Created by Roman on 2/11/17.
//  Copyright © 2017 Rocanrol. All rights reserved.
//

import UIKit

class DateUtil {
    
    /**
    * Retorna a diferença em dias entre hoje e dateTime. Só conta +1 dia após decorridas 24 horas.
    * dateTime: (NSNumber) timestamp da data a ser comparada
    */
    class func getDaysAgo(_ dateTime: NSNumber) -> Int {
        
        var daysAgo: Int
        let nowDate = Date(timeIntervalSince1970: CFAbsoluteTimeGetCurrent())
        let earlyDate = Date(timeIntervalSince1970: dateTime as! TimeInterval)
        let cal = Calendar.current
        let components = (cal as NSCalendar).components(.day, from: earlyDate, to: nowDate, options: [])
        daysAgo = components.day!
        
        return daysAgo
    }
    
    /**
     * Retorna a diferença em dias entre hoje e dateTime. Só conta +1 hora após decorridos 60 minutos.
     * dateTime: (NSNumber) timestamp da data a ser comparada
     */
    class func getHoursAgo(_ dateTime: NSNumber) -> Int {
        var hoursAgo: Int
        let nowDate = Date(timeIntervalSince1970: CFAbsoluteTimeGetCurrent())
        let earlyDate = Date(timeIntervalSince1970: dateTime as! TimeInterval)
        let cal = Calendar.current
        let components = (cal as NSCalendar).components(.hour, from: earlyDate, to: nowDate, options: [])
        hoursAgo = components.hour!
        
        return hoursAgo
    }
    
    /**
     * Retorna a diferença em minutos entre agora e dateTime. Só conta +1 minutos após decorridos 60 segundos.
     * dateTime: (NSNumber) timestamp da data a ser comparada
     */
    class func getMinutesAgo(_ dateTime: NSNumber) -> Int {
        var minutesAgo: Int
        let nowDate = Date(timeIntervalSince1970: CFAbsoluteTimeGetCurrent())
        let earlyDate = Date(timeIntervalSince1970: dateTime as! TimeInterval)
        let cal = Calendar.current
        let components = (cal as NSCalendar).components(.minute, from: earlyDate, to: nowDate, options: [])
        minutesAgo = components.minute!
        
        return minutesAgo
    }
    
    /**
     * Retorna a diferença em segundos entre agora e dateTime.
     * dateTime: (NSNumber) timestamp da data a ser comparada
     */
    class func getSecondsAgo(_ dateTime: NSNumber) -> Int {
        
        let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let date = Date(timeIntervalSince1970: dateTime.doubleValue as TimeInterval)
        let interval = Calendar.current.dateComponents(units, from: date, to: Date())
        
        return interval.second as Int? ?? 0
    }
    
    class func getNow() -> Double {
        return CFAbsoluteTimeGetCurrent() as TimeInterval
    }
    
    class func getDistantPast() -> Double {
        return Date.distantPast.timeIntervalSince1970
    }
    
    /**
     * Faz o parse da data no formato 00:00 AM
     */
    class func ParseStringDateToDouble(_ stringDate: String) -> Date {
        
        let locale = Locale(identifier: "en_US_POSIX")
        
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        let formatterWithoutMS = DateFormatter()
        formatterWithoutMS.locale = locale
        formatterWithoutMS.timeZone = TimeZone(identifier: "UTC")
        formatterWithoutMS.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: stringDate) as Date? {
            return date
        } else if let simpleDate = formatterWithoutMS.date(from: stringDate) as Date? {
            return simpleDate
        } else {
            print("ERROR: Date format \(stringDate) not recognized")
            return Date(timeIntervalSince1970: 0)
        }
    }

    class func GetHour(_ dateTime: Double = Date().timeIntervalSince1970) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let longFormatWithoutYear = DateFormatter.dateFormat(fromTemplate: "hh a", options: 0, locale: dateFormatter.locale)
        dateFormatter.dateFormat = longFormatWithoutYear
        
        let date = Date(timeIntervalSince1970: dateTime as TimeInterval)
        return dateFormatter.string(from: date)
    }
    
    class func GetHourInterval(_ startDate: Double, endDate: Double) -> String {
        var startString = DateUtil.GetHour(startDate).lowercased().replacingOccurrences(of: " ", with: "")
        let endString = DateUtil.GetHour(endDate).lowercased().replacingOccurrences(of: " ", with: "")

        if startString.hasSuffix("am") && startString.hasSuffix("am") || startString.hasSuffix("pm") && startString.hasSuffix("pm") {
            let stringArray = startString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            startString = stringArray.joined(separator: "")
        }
        
        return "\(startString) to \(endString)"
    }
    
    class func GetBirthDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let longFormatWithoutYear = DateFormatter.dateFormat(fromTemplate: "MMMM d yyyy", options: 0, locale: dateFormatter.locale)
        dateFormatter.dateFormat = longFormatWithoutYear
        
        return dateFormatter.string(from: date).capitalized
    }
    
    class func GetDate(_ dateTime: Double = Date().timeIntervalSince1970) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
//        let longFormatWithoutYear = DateFormatter.dateFormat(fromTemplate: "EEEE MMM d", options: 0, locale: dateFormatter.locale)
//        dateFormatter.dateFormat = longFormatWithoutYear
        dateFormatter.dateFormat = "MMMM d, yyyy"
        
        let date = Date(timeIntervalSince1970: dateTime as TimeInterval)
        return dateFormatter.string(from: date).capitalized
    }
    
    class func GetDateTime(_ dateTime: Double = Date().timeIntervalSince1970) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        dateFormatter.dateFormat = "MMMM d, yyyy' @ 'h:mma"
        
        let date = Date(timeIntervalSince1970: dateTime as TimeInterval)
        return dateFormatter.string(from: date)
    }

    class func GetYear(_ dateTime: Double = Date().timeIntervalSince1970) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let longFormatWithoutYear = DateFormatter.dateFormat(fromTemplate: "YYYY", options: 0, locale: dateFormatter.locale)
        dateFormatter.dateFormat = longFormatWithoutYear
        
        let date = Date(timeIntervalSince1970: dateTime as TimeInterval)
        return dateFormatter.string(from: date)
    }
    
    class func GetDayOfMonthSuffix(_ dateTime: Double = Date().timeIntervalSince1970) -> String {
        
        let date = Date(timeIntervalSince1970: dateTime as TimeInterval)
        
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.era, .year, .month, .day], from: date)
        
        let day = components.day
        
        if day! >= 11 && day! <= 13 {
            return "th";
        }
        switch day! % 10 {
            case 1:  return "st";
            case 2:  return "nd";
            case 3:  return "rd";
            default: return "th";
        }
    }
}
