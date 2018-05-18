//
//  PatientService.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-15.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Alamofire
import Foundation

class PatientService: BaseTaskController {
    static let Instance = PatientService()
    
    func addPatient(_ name: String, patientNumber: String, birthDate: Date, phoneNumber: String, address: String, completion: @escaping (_ success: Bool, _ patient: Patient?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPatient)\(self.URLAddPatientSuffix)"
        print("Connect to Server at \(url)")
        
        let parameters = ["name" : name,
                          "patient_number" : patientNumber,
                          "birthday" : birthDate,
                          "phone_number" : phoneNumber,
                          "address" : address] as [String : Any]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, nil)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let result = response.result.value as? [String : AnyObject] {
                        
                        if  let _p = result["patient"] as? [String: AnyObject],
                            let _id = _p["_id"] as? String,
                            let _name = _p["name"] as? String,
                            let _patientNumber = _p["patient_number"] as? String,
                            let _birthdate = _p["birthday"] as? String,
                            let _phoneNumber = _p["phone_number"] as? String,
                            let _address = _p["address"] as? String,
                            let _createdAt = _p["createdAt"] as? String,
                            let _user = UserController.Instance.getUser() as User? {
                            
                            // Create final Patient
                            // Create Meta
                            let _meta = Meta(createdAt: _createdAt)
                            
                            if let _updatedAt = _p["updatedAt"] as? String {
                                _meta.updatedAt = _updatedAt
                            }
                            
                            let patient = Patient(id: _id, name: _name, patientNumber: _patientNumber, birthdate: _birthdate, phoneNumber: _phoneNumber, address: _address, meta: _meta, user: _user)
                            
                            completion(true, patient)
                            
                        } else {
                            completion(false, nil)
                        }
                        
                    } else {
                        
                        completion(false, nil)
                        
                    }
                    
                } else {
                    
                    completion(false, nil)
                    
                }
                
        }
        
    }
    
    func editPatient(_ patientId: String, name: String, patientNumber: String, birthDate: Date, phoneNumber: String, address: String, completion: @escaping (_ success: Bool, _ patient: Patient?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPatient)\(self.URLEditPatientSuffix)/\(patientId)"
        print("Connect to Server at \(url)")
        
        let parameters = ["name" : name,
                          "patient_number" : patientNumber,
                          "birthday" : birthDate,
                          "phone_number" : phoneNumber,
                          "address" : address] as [String : Any]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, nil)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let result = response.result.value as? [String : AnyObject] {
                        
                        if  let _p = result["patient"] as? [String: AnyObject],
                            let _id = _p["_id"] as? String,
                            let _name = _p["name"] as? String,
                            let _patientNumber = _p["patient_number"] as? String,
                            let _birthdate = _p["birthday"] as? String,
                            let _phoneNumber = _p["phone_number"] as? String,
                            let _address = _p["address"] as? String,
                            let _createdAt = _p["createdAt"] as? String,
                            let _user = UserController.Instance.getUser() as User? {
                            
                            // Create final Patient
                            // Create Meta
                            let _meta = Meta(createdAt: _createdAt)
                            
                            if let _updatedAt = _p["updatedAt"] as? String {
                                _meta.updatedAt = _updatedAt
                            }
                            
                            let patient = Patient(id: _id, name: _name, patientNumber: _patientNumber, birthdate: _birthdate, phoneNumber: _phoneNumber, address: _address, meta: _meta, user: _user)
                            
                            completion(true, patient)
                            
                        } else {
                            completion(false, nil)
                        }
                        
                    } else {
                        
                        completion(false, nil)
                        
                    }
                    
                } else {
                    
                    completion(false, nil)
                    
                }
                
        }
        
    }
    
    func getPatients(_ skip : Int = 0, limit: Int = 1000, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPatient)\(self.URLGetPatientsSuffix)?skip=\(skip)&limit=\(limit)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                var patients: [Patient] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _patients = response.result.value as? [[String : AnyObject]] {
                        
                        for _p in _patients {
                            
                            if  let _id = _p["_id"] as? String,
                                let _name = _p["name"] as? String,
                                let _patientNumber = _p["patient_number"] as? String,
                                let _birthdate = _p["birthday"] as? String,
                                let _phoneNumber = _p["phone_number"] as? String,
                                let _address = _p["address"] as? String,
                                let _createdAt = _p["createdAt"] as? String,
                                let _userObj = _p["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _userName = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = _p["updatedAt"] as? String {
                                    _meta.updatedAt = _updatedAt
                                }
                                
                                // Create User
                                let _user = User(id: _userId, fullName: _userName, email: "")
                                
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
                                
                                // Create final Patient
                                let patient = Patient(id: _id, name: _name, patientNumber: _patientNumber, birthdate: _birthdate, phoneNumber: _phoneNumber, address: _address, meta: _meta, user: _user)
                                
                                patients.append(patient)
                                
                            }
                            
                        }
                        
                        PatientController.Instance.setPatients(patients)
                        completion(true)
                        
                    } else {
                        
                        PatientController.Instance.setPatients([])
                        completion(false)
                        
                    }
                    
                } else {
                    
                    PatientController.Instance.setPatients([])
                    completion(false)
                    
                }
                
        }
        
    }
    
    func getPatientIdByPHN(PHN: String, completion: @escaping (_ success: Bool, _ PHN: String?, _ patientId: String?, _ patientName: String?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPatient)\(self.URLGetPatientIdByPHNSuffix)/\(PHN)"
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
                        let patientId = result["id"] as? String,
                        let patientName = result["name"] as? String {
                        completion(true, PHN, patientId, patientName)
                    } else {
                        completion(false, nil, nil, nil)
                    }
                    
                } else {
                    completion(false, nil, nil, nil)
                }
                
        }
        
    }
    
    func getPatientById(patientId: String, completion: @escaping (_ success: Bool, _ patient: Patient?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPatient)\(self.URLGetPatientByIDSuffix)/\(patientId)"
        print("Connect to Server at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false, nil)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let result = response.result.value as? [String : AnyObject] {
                        
                        if  let _p = result["patient"] as? [String: AnyObject],
                            let _id = _p["_id"] as? String,
                            let _name = _p["name"] as? String,
                            let _patientNumber = _p["patient_number"] as? String,
                            let _birthdate = _p["birthday"] as? String,
                            let _phoneNumber = _p["phone_number"] as? String,
                            let _address = _p["address"] as? String,
                            let _createdAt = _p["createdAt"] as? String,
                            let _userObj = _p["user"] as? NSDictionary,
                            let _userId = _userObj["_id"] as? String,
                            let _userName = _userObj["name"] as? String {
                            
                            // Create Meta
                            let _meta = Meta(createdAt: _createdAt)
                            
                            if let _updatedAt = _p["updatedAt"] as? String {
                                _meta.updatedAt = _updatedAt
                            }
                            
                            // Create User
                            let _user = User(id: _userId, fullName: _userName, email: "")
                            
                            if let _userPhoto = _userObj["photo"] as? String {
                                _user.photo = _userPhoto
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
                            
                            // Create final Patient
                            let patient = Patient(id: _id, name: _name, patientNumber: _patientNumber, birthdate: _birthdate, phoneNumber: _phoneNumber, address: _address, meta: _meta, user: _user)
                            
                            completion(true, patient)
                            
                        } else {
                            completion(false, nil)
                        }
                        
                    } else {
                        
                        completion(false, nil)
                        
                    }
                    
                } else {
                    
                    completion(false, nil)
                    
                }
                
        }
        
    }
    
}
