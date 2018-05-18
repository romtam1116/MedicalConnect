//
//  HistoryController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-04-13.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import Foundation

class HistoryController: NSObject {
    
    static let Instance = HistoryController()
    
    fileprivate var histories: [History] = []
    
    //MARK: Consulters
    
    func getHistories() -> [History] {
        return self.histories
    }
    
    func setHistories(_ histories: [History]) {
        self.histories = histories
    }

}
