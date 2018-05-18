//
//  PostService.swift
//  MedicalConsult
//
//  Created by Akio Yamadera on 17/06/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Alamofire
import Foundation

class NotificationService: BaseTaskController {
    
    static let Instance = NotificationService()
    
    func markAsRead(_ unreadId: String, completion: @escaping (_ success: Bool, _ count: Int?) -> Void) {
        let url = "\(self.baseURL)\(self.URLNotification)/markread/\(unreadId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .post, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
//                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, nil)
                    return
                }
                
                if let value = response.result.value as? Dictionary<String, Any> {
                    completion(response.response?.statusCode == 200, value["count"] as? Int)
                } else {
                    completion(response.response?.statusCode == 200, nil)
                }
        }
    }
    
    func markAllAsRead(completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLNotification)/allread/markallread"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .post, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
//                    print("Response: \(response.result.value!)")
                }
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                completion(response.response?.statusCode == 200)
        }
    }
    
    func getNotifications(_ skip : Int = 0, limit: Int = 1000, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLNotification)?skip=\(skip)&limit=\(limit)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
//                if let _ = response.result.value {
//                    print("Response: \(response.result.value!)")
//                }
                
                var notifications: [Notification] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _notifications = response.result.value as? [[String : AnyObject]] {
                        var firstNotifcation = true
                        
                        for n in _notifications {
                            
                            if  let _nid = n["_id"] as? String,
                                let _message = n["message"] as? String,
                                let _notificationType = n["notificationType"] as? Int,
                                let _createdAt = n["createdAt"] as? String,
                                let _isRead = n["isRead"] as? Int,
                                let _userObj = n["fromUser"] as? NSDictionary {
                                
                                if firstNotifcation {
                                    firstNotifcation = false
                                    
                                    if _nid != UserDefaultsUtil.LoadLastNotificationID() {
                                        UserDefaultsUtil.SaveLastNotificationID(id: _nid)
                                    }
                                }
                                
                                let _id = _userObj["_id"] as! String
                                let _name = _userObj["name"] as! String
                                
                                let _user = User(id: _id, fullName: _name)
                                
                                if let _userPhoto = _userObj["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _userObj["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _userObj["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _userObj["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _userObj["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _userObj["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _userObj["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _title = _userObj["title"] as? String {
                                    _user.title = _title
                                }
                                
                                if let _msp = _userObj["msp"] as? String {
                                    _user.msp = _msp
                                }
                                
                                if let _location = _userObj["location"] as? String {
                                    _user.location = _location
                                }
                                
                                let notification = Notification(id: _nid, notificationType: NotificationType(rawValue: _notificationType)!, message: _message, date: _createdAt, fromUser: _user, isRead: _isRead)
                                
                                if let _broadcastObj = n["broadcast"] as? NSDictionary,
                                    let _id = _broadcastObj["_id"] as? String,
                                    let _audio = _broadcastObj["audio"] as? String,
                                    let _createdAt = _broadcastObj["createdAt"] as? String,
                                    let _playCount = _broadcastObj["play_count"] as? Int,
                                    let _commentsCount = _broadcastObj["comments_count"] as? Int,
                                    let _title = _broadcastObj["title"] as? String,
                                    let _postType = _broadcastObj["post_type"] as? String {
                                    
                                    // Create Meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = _broadcastObj["updatedAt"] as? String {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    // Create final Post
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, user: _user, postType: _postType)
                                    
                                    // Optional description
                                    
                                    if let _description = _broadcastObj["description"] as? String {
                                        post.descriptions = _description
                                    }
                                    
                                    // Optional likes
                                    
                                    if let _likes = _broadcastObj["likes"] as? [String] {
                                        
                                        post.likes = _likes
                                    }
                                    
                                    // Optional commentedUsers
                                    
                                    if let _commentedUsers = _broadcastObj["commented_users"] as? [String] {
                                        
                                        post.commentedUsers = _commentedUsers
                                    }
                                    
                                    // Optional patient id
                                    
                                    if let _patientId = _broadcastObj["patientId"] as? String {
                                        post.patientId = _patientId
                                    }
                                    
                                    // Optional referring users
                                    
                                    if let _referringUsers = _broadcastObj["referring_user"] as? [[String : AnyObject]] {
                                        for referringUser in _referringUsers {
                                            if let _referUserId = referringUser["_id"] as? String,
                                                let _referUserEmail = referringUser["email"] as? String {
                                                let _referUserName = referringUser["name"] as? String ?? ""
                                                let _referUser = User(id: _referUserId, fullName: _referUserName, email: _referUserEmail)
                                                
                                                if let _userPhoto = referringUser["photo"] as? String {
                                                    _referUser.photo = _userPhoto
                                                }
                                                
                                                post.referringUsers.append(_referUser)
                                            }
                                        }
                                    }
                                    
                                    // Optional deleted users
                                    
                                    if let _deletedUsers = _broadcastObj["deleted_users"] as? [String] {
                                        post.deletedUsers = _deletedUsers
                                    }
                                    
                                    // Optional order number
                                    
                                    if let _orderNumber = _broadcastObj["order_number"] as? String {
                                        post.orderNumber = _orderNumber
                                    }
                                    
                                    // Optional transcription url
                                    
                                    if let _transcriptionUrl = _broadcastObj["transcription_url"] as? String {
                                        post.transcriptionUrl = _transcriptionUrl
                                    }
                                    
                                    // Optional patient name
                                    
                                    if let _patientName = _broadcastObj["patient_name"] as? String {
                                        post.patientName = _patientName
                                    }
                                    
                                    // Optional patient PHN
                                    
                                    if let _patientPHN = _broadcastObj["patient_phn"] as? String {
                                        post.patientPHN = _patientPHN
                                    }
                                    
                                    notification.broadcast = post
                                    
                                }
                                
                                notifications.append(notification)
                                
                            }
                            
                        }
                        
                        NotificationController.Instance.setNotifications(notifications)
                        completion(true)
                        
                    } else {
                        
                        NotificationController.Instance.setNotifications([])
                        completion(false)
                        
                    }
                    
                    
                } else {
                    
                    NotificationController.Instance.setNotifications([])
                    completion(false)
                    
                }
                
        }
        
    }
    
    func sendMissedCallAlert(toUser: String, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLNotification)/sendmissedcallalert"
        let params = ["toUser": toUser]
        
        manager!.request(url, method: .post, parameters: params, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
        }
    }

}
