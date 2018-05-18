//
//  PostController.swift
//  MedicalConsult
//
//  Created by Akio Yamadera on 19/06/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

class NotificationController {
    
    static let Instance = NotificationController()
    
    fileprivate var notifications: [Notification] = []
    fileprivate var animatedNotifIDs: [String] = []
    
    //MARK: Notifications
    
    func getNotifications() -> [Notification] {
        return self.notifications
    }
    
    func setNotifications(_ notifications: [Notification]) {
        self.notifications = notifications
    }
    
    func getUnreadNotificationCount() -> Int {
        var count = 0
        
        for index in 0..<self.notifications.count {
            if self.notifications[index].isRead == 0 {
                count += 1
            }
        }
        
        return count
    }
    
    func markAllRead() {
        for index in 0..<self.notifications.count {
            self.notifications[index].isRead = 1
        }
    }
    
    func addAnimatedNotifID(_ id: String) {
        self.animatedNotifIDs.append(id)
    }
    
    func checkIfAnimated(_ id: String) -> Bool {
        return self.animatedNotifIDs.contains(id)
    }
    
    func setAnimatedNotifIDs(_ animatedNotifIDs: [String]) {
        self.animatedNotifIDs = animatedNotifIDs
    }
    
}
