//
//  MTScrollView.swift
//  MedicalConsult
//
//  Created by Roman Zoffoli on 27/03/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class MTScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    func setSimultaneousGestures() {
        self.panGestureRecognizer.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let _panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            
            let velocity = _panGesture.velocity(in: self)
            return velocity.x < 0

        }
        
        return false
    }
}
