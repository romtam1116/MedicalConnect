//
//  BaseTaskController.swift
//  MedicalConsult
//
//  Created by Roman on 12/29/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Foundation
import Alamofire

class BaseTaskController {
    let baseURL = "http://medic-app-dev.us-east-2.elasticbeanstalk.com/medic_back/api"
//    let baseURL = "http://medicappproduct.us-east-2.elasticbeanstalk.com/medic_back/api"
//    let baseURL = "http://codi-dev-test.us-east-2.elasticbeanstalk.com/medic_back/api"
    
    let URLSignUp = "/signup"
    let URLLogin = "/login"
    let URLUser = "/user"
    let URLPost = "/post"
    let URLComment = "/comment"
    let URLNotification = "/notification"
    let URLPatient = "/patients"
    let URLReport = "/report"
    let URLSearch = "/search"
    
    let URLForgetPassword = "/forgotPassword"
    let URLUpdatePassword = "/resetPassword"
    
    let URLFollowSuffix = "/follow"
    let URLUnfollowSuffix = "/unfollow"
    let URLDeviceToken = "/deviceToken"
    
    let URLLikeSuffix = "/like"
    let URLUnlikeSuffix = "/unlike"
    let URLPlaceOrderSuffix = "/transcription"
    
    let URLBlockSuffix = "/block"
    let URLUnblockSuffix = "/unblock"
    
    let URLMakePrivateSuffix = "/makeprivate"
    let URLMakeUnprivateSuffix = "/makeunprivate"
    
    let URLAcceptRequestSuffix = "/accept"
    let URLDeclineRequestSuffix = "/decline"
    
    let URLGetPostSuffix = "/getpost"
    let URLGetRecentPostSuffix = "/getrecentpost"
    let URLGetPostLikesSuffix = "/getpostlikes"
    
    let URLMakeNotiFilterSuffix = "/setnotificationfilter"
    
    let URLGetTrendingHashtagsSuffix = "/gettrendinghashtags"
    let URLGetPostsFromHashtagSuffix = "/getpostsfromhashtag"
    let URLGetNotesByPatientIdSuffix = "/getnotesbypatientid"
    
    let URLAddPatientSuffix = "/addpatient"
    let URLEditPatientSuffix = "/editpatient"
    let URLGetPatientsSuffix = "/getpatients"
    let URLGetPatientIdByPHNSuffix = "/getpatientid"
    let URLGetPatientByIDSuffix = "/getpatientbyid"
    
    let URLGetUserIdByMSPSuffix = "/getuseridbymsp"
    let URLUpdateAvailability = "/consulters/updateavailability"
    
    let URLGetCallHistory = "/history/getcallhistory"
    let URLUpdateCallHistory = "/history/updatecall"
    
    var simpleManager: SessionManager?
    var manager: SessionManager?
    
    enum Response {
        case success
        case failure
        case noConnection
    }
    
    init() {
        DataRequest.addAcceptableImageContentTypes(["image/jpg"])
        self.configureInstance(UserDefaultsUtil.LoadToken())
    }

    func configureInstance(_ token: String) {
        
        let bearer = "Bearer \(token)"
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : bearer, "user-agent" : UIDevice.current.identifierForVendor!.uuidString.sha1()]
        self.manager = SessionManager(configuration: configuration)
        
        let simpleConfiguration = URLSessionConfiguration.default
        simpleConfiguration.httpAdditionalHeaders = ["user-agent" : UIDevice.current.identifierForVendor!.uuidString.sha1()]
        self.simpleManager = SessionManager(configuration: simpleConfiguration)
        
    }
}
