//
//  Comment.swift
//  MedicalConsult
//
//  Created by Roman on 12/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Foundation

class Comment {
    
    var url: String
    var author: String
    var date: String
    var comment: String
    var size: CGFloat = 0.0
    var user: User

    init(url: String, author: String, date: String, comment: String, user: User) {
        
        self.url = url
        self.author = author
        self.date = date
        self.comment = comment
        self.user = user
        
    }
    
    init(date: String, comment: String) {
        
        self.url = ""
        self.author = ""
        self.date = date
        self.comment = comment
        self.user = User(email: "", password: "")
        
    }
    
    func setSize(size: CGFloat) {
        
        self.size = size
        
    }
    
    func getFormattedDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.date) as NSDate
        let formattedDate = dDate.dateTimeAgo() as String? ?? ""
        
        return formattedDate
        
    }
}
