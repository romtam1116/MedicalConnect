//
//  SearchController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-09-21.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

class SearchController {
    
    static let Instance = SearchController()
    
    fileprivate var keyword: String = ""
    fileprivate var hashtags: [String] = []
    
    //MARK: Hashtags
    
    func getKeyword() -> String {
        return self.keyword
    }
    
    func setKeyword(_ keyword: String) {
        self.keyword = keyword
    }
    
    //MARK: Hashtags
    
    func getHashtags() -> [String] {
        return self.hashtags
    }
    
    func setHashtags(_ hashtags: [String]) {
        self.hashtags = hashtags
    }
    
}
