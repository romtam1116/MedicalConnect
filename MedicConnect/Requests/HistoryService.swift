//
//  HistoryService.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-04-13.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import Alamofire
import Foundation

class HistoryService: BaseTaskController {
    
    static let Instance = HistoryService()
    
    func updateCallHistory(callId: String, callState: Int, duration: Double, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUpdateCallHistory)"
        print("Connect to Server at \(url)")
        
        let parameter = [
            "callId": callId,
            "callState": callState,
            "duration": duration
        ] as [String : Any]
        
        print(parameter)
        
        manager!.request(url, method: .post, parameters: parameter, encoding: URLEncoding.default)
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
    
    func getCallHistory(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLGetCallHistory)?skip=\(0)&limit=\(20)"
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
                
                var histories: [History] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _histories = response.result.value as? [[String : AnyObject]] {
                        
                        for _h in _histories {
                            
                            if let _id = _h["_id"] as? String,
                                let _createdAt = _h["createdAt"] as? String,
                                let _callId = _h["callId"] as? String,
                                let _callState = _h["callState"] as? Int,
                                let _duration = _h["duration"] as? Double,
                                let _type = _h["type"] as? String,
                                let _fromUser = _h["fromUser"] as? NSDictionary,
                                let _fromUserId = _fromUser["_id"] as? String,
                                let _fromUserName = _fromUser["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = _h["updatedAt"] as? String {
                                    _meta.updatedAt = _updatedAt
                                }
                                
                                // Create fromUser
                                let _user = User(id: _fromUserId, fullName: _fromUserName, email: "")
                                
                                if let _userPhoto = _fromUser["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _title = _fromUser["title"] as? String {
                                    _user.title = _title
                                }
                                
                                if let _msp = _fromUser["msp"] as? String {
                                    _user.msp = _msp
                                }
                                
                                if let _location = _fromUser["location"] as? String {
                                    _user.location = _location
                                }
                                
                                let toUser = UserController.Instance.getUser()
                                
                                // Create final History
                                let history = History(id: _id, meta: _meta, callId: _callId, callState: _callState, duration: _duration, fromUser: _user, toUser: toUser!, type: _type)
                                histories.append(history)
                                
                            }
                            
                        }
                        
                        HistoryController.Instance.setHistories(histories)
                        completion(true)
                        
                    } else {
                        print("No Histories.")
                        HistoryController.Instance.setHistories([])
                        completion(false)
                    }
                    
                } else {
                    HistoryController.Instance.setHistories([])
                    completion(false)
                }
        }
        
    }
    
}
