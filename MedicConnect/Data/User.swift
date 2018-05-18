//
//  User.swift
//  MedicalConsult
//
//  Created by Roman on 11/26/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Foundation

class User {
    
    var id: String
    var fullName: String
    var email: String
    var password: String
    var photo: String = ""
    var phoneNumber: String = ""
    var title: String = ""
    var msp: String = ""
    var location: String = ""
    var posts: [Post] = []
    var following: [AnyObject] = []
    var follower: [AnyObject] = []
    var blocking: [AnyObject] = []
    var blockedby: [AnyObject] = []
    var requested: [AnyObject] = []
    var requesting: [AnyObject] = []
    var isprivate: Bool = false
    var notificationfilter: Int = 31
    var deviceToken: String?
    var playCount: Int = 0
    
    // Signup constructor
    
    init (fullName: String, email: String, password: String) {
        
        self.id = ""
        self.fullName = fullName
        self.email = email
        self.password = password
        self.photo = ""
        
    }
    
    // Signin constructor
    
    init (email: String, password: String) {
        
        self.id = ""
        self.fullName = ""
        self.email = email
        self.password = password
        self.photo = ""
        
    }
    
    // Refresh constructor
    
    init (id: String, fullName: String, email: String) {
        
        self.id = id
        self.fullName = fullName
        self.email = email
        self.password = ""
        
    }
    
    // Get all and Follow constructor
    
    init (id: String, fullName: String) {
        
        self.id = id
        self.fullName = fullName
        self.email = ""
        self.password = ""
        
    }
    
    func getInitials() -> String {
        
        let separated = self.fullName.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        
        if self.fullName.isEmpty {
            return ""
        } else {
            return separated.reduce("") { $0 + String($1.first!) }
        }
        
    }
    
    func getPosts(type: String) -> [Post] {
        
        let posts = self.posts.filter({(post: Post) -> Bool in
            if type == Constants.PostTypeAll {
                return true
            } else if type == Constants.PostTypeConsult {
                return post.postType == type || post.postType == Constants.PostTypeNote
            } else {
                return post.postType == type
            }
        })
        
        return posts
        
    }
    
    func getPostIndex(id: String) -> Int? {
        
        let index = self.posts.index(where: { (post) -> Bool in
            post.id == id
        })
        
        return index
        
    }
    
}
