//
//  UserService.swift
//  MedicalConsult
//
//  Created by Roman on 12/29/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Alamofire
import Foundation

class UserService: BaseTaskController {
    
    static let Instance = UserService()
    
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var expectedContentLength = 0
    let MaximumImageSize: Int = 2097152
    
    func signup(_ user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLSignUp)"
        print("Connect to Server at \(url)")
        
        let parameters = ["password" : user.password, "email" : user.email, "name" : user.fullName]
        
        simpleManager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, "")
                    return
                }
                
                if response.response?.statusCode == 200 {
                    if let _dic = response.result.value as? NSDictionary,
                        let _token = _dic["token"] as? String {
                        
                        UserDefaultsUtil.SaveToken(_token)
                        
                        UserService.Instance.getMe(completion: {
                            (user: User?) in
                            
                            if let _user = user as User? {
                                UserController.Instance.setUser(_user)
                                completion(true, "")
                            } else {
                                completion(false, "Inconsistent server response. Please try again later.")
                            }
                            
                        })
                    } else {
                        completion(false, "Inconsistent server response. Please try again later.")
                    }
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "Server Down")
                    }
                }
                
        }
    }
    
    func login(_ user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLLogin)"
        print("Connect to Server at \(url)")
        
        let parameters = ["password" : user.password, "email" : user.email]
        
        simpleManager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, "")
                    return
                }
                let code = response.response?.statusCode
                if code == 200 {
                    if let _dic = response.result.value as? NSDictionary,
                        let _token = _dic["token"] as? String {

                        UserDefaultsUtil.SaveToken(_token)

                        UserService.Instance.getMe(completion: {
                            (user: User?) in

                            if let _user = user as User? {
                                UserController.Instance.setUser(_user)
                                completion(true, "")
                            } else {
                                completion(false, "Inconsistent server response. Please try again later.")
                            }

                        })
                    } else {
                        completion(false, "Inconsistent server response. Please try again later.")
                    }
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "Server Down")
                    }

                }
                
        }
    }
    
    func postUserImage(id: String, image: UIImage, completion: @escaping (_ success: Bool) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") else {
            return
        }
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            if let _image = image as UIImage?,
                let _imageData = UIImageJPEGRepresentation(_image, 0.7){
                
                multipartFormData.append(_imageData, withName: "photo", fileName: "\(Date().timeIntervalSinceReferenceDate).jpg", mimeType: "image/jpeg")
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in

                    completion(response.response!.statusCode == 200)
                    
                }
                
            case .failure(let encodingError):
                print(encodingError)
                completion(false)
            }
            
        })
        
    }
    
    func editUser(user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        
        let parameters = ["name" : user.fullName,
                          "title" : user.title,
                          "msp" : user.msp,
                          "location" : user.location,
                          "phone" : user.phoneNumber,
                          "email" : user.email]
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    
                    if response.response?.statusCode == 200 {
                        completion(true, "")
                    } else {
                        if let _dic = response.result.value as? NSDictionary,
                            let _message = _dic["error"] as? String {
                            completion(false, _message)
                        } else {
                            completion(false, "Server Down")
                        }
                    }
                    
                }
                
            case .failure:
                completion(false, "Server Down")
            }
            
        })
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        
        let parameters = ["oldPassword" : currentPassword, "newPassword" : newPassword]
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    
                    if response.response?.statusCode == 200 {
                        completion(true, "")
                    } else {
                        if let _dic = response.result.value as? NSDictionary,
                            let _message = _dic["error"] as? String {
                            completion(false, _message)
                        } else {
                            completion(false, "Server Down")
                        }
                    }
                    
                }
                
            case .failure:
                completion(false, "Server Down")
            }
            
        })
    }
    
    func forgotPassword(email: String, token: String, completion: @escaping (_ success: Bool, _ code: Int?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLForgetPassword)"
        print("Connect to Server at \(url)")
        
        let parameters = ["email" : email, "token": token]
        
        self.manager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                completion(response.response?.statusCode == 200, response.response?.statusCode)
                
        }
    }
    
    func updatePassword(token: String, new: String, completion: @escaping (_ success: Bool, _ code: Int?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUpdatePassword)/\(token)"
        print("Connect to Server at \(url)")
        
        let parameters = ["updatePassword" : new]
        
        self.manager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                completion(response.response?.statusCode == 200, response.response?.statusCode)
                
        }
    }
    
    func deleteAccount(completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        print("Connect to Server at \(_url)")
        
        self.manager!.request(_url, method: .delete, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if response.response?.statusCode == 200 {
                    completion(true, "")
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "Server Down")
                    }
                }
                
        }
    }
    
    func makePrivate(value: Bool, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = (value==true) ? "\(self.baseURL)\(self.URLUser)\(self.URLMakePrivateSuffix)" : "\(self.baseURL)\(self.URLUser)\(self.URLMakeUnprivateSuffix)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                print(response.result.value ?? "")
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
        
    }
    
    func setNotificationFilter(value: Int, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLMakeNotiFilterSuffix)?filterValue=\(value)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                print(response.result.value ?? "")
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
        
    }
    
    func getMe(completion: @escaping (_ user: User?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/me"
        print("Connect to Server at \(url)")
        
        self.manager!.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(nil)
                    return
                }
                
                if let _ = response.result.value {
//                    print("Response: \(response.result.value!)")
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _dic = response.result.value as? NSDictionary,
                        let _userId = _dic["_id"] as? String,
                        let _email = _dic["email"] as? String {
                        
                        let _name = _dic["name"] as? String ?? ""
                        
                        let _user = User(id: _userId, fullName: _name, email: _email)
                        
                        if let _userPhoto = _dic["photo"] as? String {
                            _user.photo = _userPhoto
                        }
                        
                        if let _title = _dic["title"] as? String {
                            _user.title = _title
                        }
                        
                        if let _msp = _dic["msp"] as? String {
                            _user.msp = _msp
                        }
                        
                        if let _location = _dic["location"] as? String {
                            _user.location = _location
                        }
                        
                        if let _phone = _dic["phone"] as? String {
                            _user.phoneNumber = _phone
                        }
                        
                        if let _isPrivate = _dic["isprivate"] as? Int {
                            _user.isprivate = (_isPrivate == 0) ? false : true
                        }
                        
                        if let _deviceToken = _dic["deviceToken"] as? String {
                            _user.deviceToken = _deviceToken
                        }
                        
                        if let _notificationfilter = _dic["notificationfilter"] as? Int {
                            _user.notificationfilter = _notificationfilter
                        }
                        
                        if let _posts = _dic["posts"] as? [[String : AnyObject]] {
                            
                            for p in _posts {
                                
                                if let _id = p["_id"] as? String,
                                    let _audio = p["audio"] as? String,
                                    let _createdAt = p["createdAt"] as? String,
                                    let _playCount = p["play_count"] as? Int,
                                    let _commentsCount = p["comments_count"] as? Int,
                                    let _title = p["title"] as? String,
                                    let _postType = p["post_type"] as? String,
                                    let _creatorObj = p["user"] as? NSDictionary,
                                    let _creatorId = _creatorObj["_id"] as? String,
                                    let _creatorName = _creatorObj["name"] as? String {
                                    
                                    // Create meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = p["updatedAt"] as? String {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    // Create Consult Creator
                                    let _creator = User(id: _creatorId, fullName: _creatorName, email: "")
                                    
                                    if let _userPhoto = _creatorObj["photo"] as? String {
                                        _creator.photo = _userPhoto
                                    }
                                    
                                    if let _title = _creatorObj["title"] as? String {
                                        _creator.title = _title
                                    }
                                    
                                    if let _msp = _creatorObj["msp"] as? String {
                                        _creator.msp = _msp
                                    }
                                    
                                    if let _location = _creatorObj["location"] as? String {
                                        _creator.location = _location
                                    }
                                    
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, description: "", user: _creator, postType: _postType)
                                    
                                    // Optional description
                                    
                                    if let _description = p["description"] as? String {
                                        post.descriptions = _description
                                    }
                                    
                                    // Optional likes
                                    
                                    if let _likes = p["likes"] as? [String] {
                                        post.likes = _likes
                                    }
                                    
                                    // Optional like description
                                    
                                    if let _likeDescription = p["like_description"] as? String {
                                        post.likeDescription = _likeDescription
                                    }
                                    
                                    // Optional commentedUsers
                                    
                                    if let _commentedUsers = p["commented_users"] as? [String] {
                                        post.commentedUsers = _commentedUsers
                                    }
                                    
                                    // Optional hashtags
                                    
                                    if let _hashtags = p["hashtags"] as? [String] {
                                        post.hashtags = _hashtags
                                    }
                                    
                                    // Optional patient id
                                    
                                    if let _patientId = p["patientId"] as? String {
                                        post.patientId = _patientId
                                    }
                                    
                                    // Optional referring users
                                    
                                    if let _referringUsers = p["referring_user"] as? [[String : AnyObject]] {
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
                                    
                                    if let _deletedUsers = p["deleted_users"] as? [String] {
                                        post.deletedUsers = _deletedUsers
                                    }
                                    
                                    // Optional order number
                                    
                                    if let _orderNumber = p["order_number"] as? String {
                                        post.orderNumber = _orderNumber
                                    }
                                    
                                    // Optional transcription url
                                    
                                    if let _transcriptionUrl = p["transcription_url"] as? String {
                                        post.transcriptionUrl = _transcriptionUrl
                                    }
                                    
                                    // Optional patient name
                                    
                                    if let _patientName = p["patient_name"] as? String {
                                        post.patientName = _patientName
                                    }
                                    
                                    // Optional patient PHN
                                    
                                    if let _patientPHN = p["patient_phn"] as? String {
                                        post.patientPHN = _patientPHN
                                    }
                                    
                                    _user.posts.append(post)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blockedby = _dic["blockedby"] as? [[String : AnyObject]] {
                            
                            for f in _blockedby {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let blockedby = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        blockedby.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        blockedby.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        blockedby.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        blockedby.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        blockedby.photo = _photo
                                    }
                                    
                                    _user.blockedby.append(blockedby)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blocking = _dic["blocking"] as? [[String : AnyObject]] {
                            
                            for f in _blocking {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let blocking = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        blocking.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        blocking.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        blocking.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        blocking.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        blocking.photo = _photo
                                    }
                                    
                                    _user.blocking.append(blocking)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _following = _dic["following"] as? [[String : AnyObject]] {
                            
                            for f in _following {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        follow.title = _title
                                    }
                                    if let _msp = f["msp"] as? String {
                                        follow.msp = _msp
                                    }
                                    if let _location = f["location"] as? String {
                                        follow.location = _location
                                    }
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    if let _blocking = _user.blocking as? [User] {
                                        let isBlocked = _blocking.contains(where: { (user) -> Bool in
                                            return (user.id == _id)
                                        })
                                        if isBlocked {
                                            continue
                                        }
                                    }
                                    _user.following.append(follow)
                                }
                                
                            }
                            
                        }
                        
                        if let followers = _dic["followers"] as? [[String : AnyObject]] {
                            
                            for f in followers {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        follow.title = _title
                                    }
                                    if let _msp = f["msp"] as? String {
                                        follow.msp = _msp
                                    }
                                    if let _location = f["location"] as? String {
                                        follow.location = _location
                                    }
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.follower.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _requested = _dic["requested"] as? [[String : AnyObject]] {
                            
                            for f in _requested {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let request = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        request.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        request.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        request.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        request.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        request.photo = _photo
                                    }
                                    
                                    _user.requested.append(request)
                                    
                                }
                                
                            }
                            
                        }
                        if let _requesting = _dic["requesting"] as? [[String : AnyObject]] {
                            
                            for f in _requesting {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let request = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        request.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        request.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        request.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        request.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        request.photo = _photo
                                    }
                                    
                                    _user.requesting.append(request)
                                    
                                }
                                
                            }
                            
                        }
                        
                        UserController.Instance.setUser(_user)
                        completion(_user)
                        
                    } else {
                        completion(nil)
                    }
                    
                } else {
                    completion(nil)
                }
                
        }
    }
    
    func getUser(forId: String, completion: @escaping (_ user: User?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/id/\(forId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(nil)
                    return
                }
                                
                if response.response?.statusCode == 200 {
                    
                    if let _dic = response.result.value as? NSDictionary,
                        let _userId = _dic["_id"] as? String,
                        let _email = _dic["email"] as? String {
                        
                        let _name = _dic["name"] as? String ?? ""
                        
                        let _user = User(id: _userId, fullName: _name, email: _email)
                        
                        if let _userPhoto = _dic["photo"] as? String {
                            _user.photo = _userPhoto
                        }
                        
                        if let _title = _dic["title"] as? String {
                            _user.title = _title
                        }
                        
                        if let _msp = _dic["msp"] as? String {
                            _user.msp = _msp
                        }
                        
                        if let _location = _dic["location"] as? String {
                            _user.location = _location
                        }
                        
                        if let _isPrivate = _dic["isprivate"] as? Int {
                            _user.isprivate = (_isPrivate == 0) ? false : true
                        }
                        
                        if let _posts = _dic["posts"] as? [[String : AnyObject]] {
                            
                            for p in _posts {
                                
                                if let _id = p["_id"] as? String,
                                    let _audio = p["audio"] as? String,
                                    let _createdAt = p["createdAt"] as? String,
                                    let _playCount = p["play_count"] as? Int,
                                    let _commentsCount = p["comments_count"] as? Int,
                                    let _title = p["title"] as? String,
                                    let _postType = p["post_type"] as? String,
                                    let _creatorObj = p["user"] as? NSDictionary,
                                    let _creatorId = _creatorObj["_id"] as? String,
                                    let _creatorName = _creatorObj["name"] as? String {
                                    
                                    // Create meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = p["updatedAt"] as? String {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    // Create Consult Creator
                                    let _creator = User(id: _creatorId, fullName: _creatorName, email: "")
                                    
                                    if let _userPhoto = _creatorObj["photo"] as? String {
                                        _creator.photo = _userPhoto
                                    }
                                    
                                    if let _title = _creatorObj["title"] as? String {
                                        _creator.title = _title
                                    }
                                    
                                    if let _msp = _creatorObj["msp"] as? String {
                                        _creator.msp = _msp
                                    }
                                    
                                    if let _location = _creatorObj["location"] as? String {
                                        _creator.location = _location
                                    }
                                    
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, description: "", user: _creator, postType: _postType)
                                    
                                    // Optional description
                                    
                                    if let _description = p["description"] as? String {
                                        post.descriptions = _description
                                    }
                                    
                                    // Optional likes
                                    
                                    if let _likes = p["likes"] as? [String] {
                                        post.likes = _likes
                                    }
                                    
                                    // Optional like description
                                    
                                    if let _likeDescription = p["like_description"] as? String {
                                        post.likeDescription = _likeDescription
                                    }
                                    
                                    // Optional commentedUsers
                                    
                                    if let _commentedUsers = p["commented_users"] as? [String] {
                                        post.commentedUsers = _commentedUsers
                                    }
                                    
                                    // Optional hashtags
                                    
                                    if let _hashtags = p["hashtags"] as? [String] {
                                        post.hashtags = _hashtags
                                    }
                                    
                                    // Optional patient id
                                    
                                    if let _patientId = p["patientId"] as? String {
                                        post.patientId = _patientId
                                    }
                                    
                                    // Optional referring users
                                    
                                    if let _referringUsers = p["referring_user"] as? [[String : AnyObject]] {
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
                                    
                                    if let _deletedUsers = p["deleted_users"] as? [String] {
                                        post.deletedUsers = _deletedUsers
                                    }
                                    
                                    // Optional order number
                                    
                                    if let _orderNumber = p["order_number"] as? String {
                                        post.orderNumber = _orderNumber
                                    }
                                    
                                    // Optional transcription url
                                    
                                    if let _transcriptionUrl = p["transcription_url"] as? String {
                                        post.transcriptionUrl = _transcriptionUrl
                                    }
                                    
                                    // Optional patient name
                                    
                                    if let _patientName = p["patient_name"] as? String {
                                        post.patientName = _patientName
                                    }
                                    
                                    // Optional patient PHN
                                    
                                    if let _patientPHN = p["patient_phn"] as? String {
                                        post.patientPHN = _patientPHN
                                    }
                                    
                                    _user.posts.append(post)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blockedBy = _dic["blockedby"] as? [AnyObject] {
                            _user.blockedby = _blockedBy
                        }
                        
                        if let _following = _dic["following"] as? [[String : AnyObject]] {
                            
                            for f in _following {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        follow.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        follow.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        follow.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.following.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let followers = _dic["followers"] as? [[String : AnyObject]] {
                            
                            for f in followers {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _title = f["title"] as? String {
                                        follow.title = _title
                                    }
                                    
                                    if let _msp = f["msp"] as? String {
                                        follow.msp = _msp
                                    }
                                    
                                    if let _location = f["location"] as? String {
                                        follow.location = _location
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.follower.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blocking = _dic["blocking"] as? [AnyObject] {
                            _user.blocking = _blocking
                        }
                        
                        
                        if let _requested = _dic["requested"] as? [AnyObject] {
                            _user.requested = _requested
                        }
                        if let _requesting = _dic["requesting"] as? [AnyObject] {
                            _user.requesting = _requesting
                        }
                        
                        completion(_user)
                        
                    } else {
                        completion(nil)
                    }
                    
                } else {
                    completion(nil)
                }
                
                
        }
    }
    
    func getAll(name: String, completion: @escaping (_ success: BaseTaskController.Response) -> Void) {
        
        //TODO: Discuss best practice for page and limit with backend dev.
        
        guard let _ = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) as String? else {
            return
        }
        
        let url = "\(self.baseURL)\(self.URLUser)/all?skip=0&limit=100"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(BaseTaskController.Response.noConnection)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _dicArray = response.result.value as? NSArray {
                        var users: [User] = []
                        
                        for d in _dicArray {
                            
                            if let _dic = d as? NSDictionary,
                                let _id = _dic["_id"] as? String,
                                let _name = _dic["name"] as? String {
                                
                                let _user = User(id: _id, fullName: _name)
                                
                                if let _userPhoto = _dic["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _dic["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _dic["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _dic["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _dic["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _dic["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _dic["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _title = _dic["title"] as? String {
                                    _user.title = _title
                                }
                                
                                if let _msp = _dic["msp"] as? String {
                                    _user.msp = _msp
                                }
                                
                                if let _location = _dic["location"] as? String {
                                    _user.location = _location
                                }
                                
                                if let _isprivate = _dic["isprivate"] as? Int {
                                    _user.isprivate = (_isprivate == 0) ? false : true
                                }
                                
                                users.append(_user)
                                
                            }
                        }
                        
                        UserController.Instance.setUsers(users)
                        completion(BaseTaskController.Response.success)
                        
                    } else {
                        completion(BaseTaskController.Response.failure)
                    }
                    
                } else {
                    completion(BaseTaskController.Response.failure)
                }
        }
    }
    
    func getTimeline(_ postType: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/timeline?postType=\(postType)&skip=0&limit=1000"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                if let _ = response.result.value {
//                    print("Response: \(response.result.value!)")
                }
                
                var posts: [Post] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _posts = response.result.value as? NSArray {
                                
                        for p in _posts {
                            
                            if let _p = p as? NSDictionary,
                                let _id = _p["_id"] as? String,
                                let _audio = _p["audio"] as? String,
                                let _createdAt = _p["createdAt"] as? String,
                                let _playCount = _p["play_count"] as? Int,
                                let _commentsCount = _p["comments_count"] as? Int,
                                let _title = _p["title"] as? String,
                                let _userObj = _p["user"] as? NSDictionary,
                                let _postType = _p["post_type"] as? String,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = _p["updatedAt"] as? String {
                                    _meta.updatedAt = _updatedAt
                                }
                                
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
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
                                
                                if let _blockedBy = _userObj["blockedby"] as? [String] {
                                    _user.blockedby = _blockedBy as [AnyObject]
                                    if let _user = UserController.Instance.getUser() as User?, _blockedBy.contains(_user.id) {
                                        continue
                                    }
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
                                
                                // Create final Post
                                let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, user: _user, postType: _postType)
                                
                                // Optional description
                                
                                if let _description = _p["description"] as? String {
                                    post.descriptions = _description
                                }
                                
                                // Optional likes
                                
                                if let _likes = _p["likes"] as? [String] {
                                    post.likes = _likes
                                }
                                
                                // Optional like description
                                
                                if let _likeDescription = _p["like_description"] as? String {
                                    post.likeDescription = _likeDescription
                                }
                                
                                // Optional commentedUsers
                                
                                if let _commentedUsers = _p["commented_users"] as? [String] {
                                    post.commentedUsers = _commentedUsers
                                }
                                
                                // Optional hashtags
                                
                                if let _hashtags = _p["hashtags"] as? [String] {
                                    post.hashtags = _hashtags
                                }
                                
                                // Optional patient id
                                
                                if let _patientId = _p["patientId"] as? String {
                                    post.patientId = _patientId
                                }
                                
                                // Optional referring users
                                
                                if let _referringUsers = _p["referring_user"] as? [[String : AnyObject]] {
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
                                
                                if let _deletedUsers = _p["deleted_users"] as? [String] {
                                    post.deletedUsers = _deletedUsers
                                }
                                
                                // Optional order number
                                
                                if let _orderNumber = _p["order_number"] as? String {
                                    post.orderNumber = _orderNumber
                                }
                                
                                // Optional transcription url
                                
                                if let _transcriptionUrl = _p["transcription_url"] as? String {
                                    post.transcriptionUrl = _transcriptionUrl
                                }
                                
                                // Optional patient name
                                
                                if let _patientName = _p["patient_name"] as? String {
                                    post.patientName = _patientName
                                }
                                
                                // Optional patient PHN
                                
                                if let _patientPHN = _p["patient_phn"] as? String {
                                    post.patientPHN = _patientPHN
                                }

                                posts.append(post)
                                
                            }
                            
                        }
                            
                        PostController.Instance.setFollowingPosts(posts)
                        completion(true)
                        
                    } else {
                        PostController.Instance.setFollowingPosts([])
                        completion(false)
                    }
                    
                } else {
                    PostController.Instance.setFollowingPosts([])
                    completion(false)
                }
        }
    }
    
    func getRecommendedUsers(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/recommended"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                var users: [User] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _users = response.result.value as? [[String : AnyObject]] {
                        
                        for _u in _users {
                            
                            if let _userId = _u["_id"] as? String,
                                let _name = _u["name"] as? String {
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
                                if let _userPhoto = _u["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _u["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _u["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _u["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _u["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _u["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _u["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _title = _u["title"] as? String {
                                    _user.title = _title
                                }
                                
                                if let _msp = _u["msp"] as? String {
                                    _user.msp = _msp
                                }
                                
                                if let _location = _u["location"] as? String {
                                    _user.location = _location
                                }
                                
                                users.append(_user)
                            }
                            
                        }
                        
                        UserController.Instance.setRecommedendUsers(users)
                        completion(true)
                        
                    } else {
                        UserController.Instance.setRecommedendUsers([])
                        completion(false)
                    }
                    
                } else {
                    UserController.Instance.setRecommedendUsers([])
                    completion(false)
                }
        }
    }
    
    func getPromotedUsers(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/getpromotedcontent"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                var users: [User] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _users = response.result.value as? [[String : AnyObject]] {
                        
                        for _u in _users {
                            
                            if let _userId = _u["_id"] as? String,
                                let _name = _u["name"] as? String {
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
                                if let _userPhoto = _u["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _u["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _u["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _u["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _u["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _u["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _u["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _title = _u["title"] as? String {
                                    _user.title = _title
                                }
                                
                                if let _msp = _u["msp"] as? String {
                                    _user.msp = _msp
                                }
                                
                                if let _location = _u["location"] as? String {
                                    _user.location = _location
                                }
                                
                                if let _playCount = _u["play_count"] as? Int {
                                    _user.playCount = _playCount
                                }
                                
                                users.append(_user)
                            }
                            
                        }
                        
                        let sortedUsers = users.sorted(by: { $0.fullName < $1.fullName })
                        
                        UserController.Instance.setPromotedUsers(sortedUsers)
                        completion(true)
                        
                    } else {
                        UserController.Instance.setPromotedUsers([])
                        completion(false)
                    }
                    
                } else {
                    UserController.Instance.setPromotedUsers([])
                    completion(false)
                }
        }
    }
    
    func block(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLBlockSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func unblock(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLUnblockSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func acceptRequest(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLAcceptRequestSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func declineRequest(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLDeclineRequestSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func follow(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLFollowSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func unfollow(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLUnfollowSuffix)/\(userId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func putDeviceToken(deviceToken: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLDeviceToken)"
        print("Connect to Server at \(url)")
        
        let parameter = ["deviceToken": deviceToken]
        manager!.request(url, method: .put, parameters: parameter, encoding: URLEncoding.default)
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
    
    func report(from: String, subject: String, msgbody: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLReport)"
        print("Connect to Server at \(url)")
        
        let parameter = ["from": from, "subject": subject, "text": msgbody]
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
    
    func getUserIdByMSP(MSP: String, completion: @escaping (_ success: Bool, _ MSP: String? , _ userId: String?, _ name: String?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLGetUserIdByMSPSuffix)/\(MSP)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, nil, nil, nil)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let result = response.result.value as? [String : AnyObject],
                        let userId = result["id"] as? String,
                        let name = result["name"] as? String {
                        completion(true, MSP, userId, name)
                    } else {
                        completion(false, nil, nil, nil)
                    }
                    
                } else {
                    completion(false, nil, nil, nil)
                }
                
        }
        
    }
    
    func updateAvailability(available: Bool, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUpdateAvailability)"
        print("Connect to Server at \(url)")
        
        let parameter = ["available": available]
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
    
}
