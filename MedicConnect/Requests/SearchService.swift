//
//  SearchService.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-09-21.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Alamofire
import Foundation

class SearchService: BaseTaskController {
    
    static let Instance = SearchService()
    
    func searchHashtags(keyword: String, completion: @escaping (_ success: Bool) -> Void) {
        
        // Store keyword
        SearchController.Instance.setKeyword(keyword)
        
        if keyword == "" {
            SearchController.Instance.setHashtags([])
            completion(true)
            return
        }
        
        let url = "\(self.baseURL)\(self.URLSearch)"
        print("Connect to Server at \(url)")
        
        let parameters = ["keyword" : keyword]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                if response.response?.statusCode == 200 && keyword == SearchController.Instance.getKeyword() {
                    if let _hashtags = response.result.value as? [String] {
                        SearchController.Instance.setHashtags(_hashtags)
                    } else {
                        SearchController.Instance.setHashtags([])
                    }
                    
                    completion(true)
                } else {
                    completion(false)
                }
                
        }
        
    }
    
}

