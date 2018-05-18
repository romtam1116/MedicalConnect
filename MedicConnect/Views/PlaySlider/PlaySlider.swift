//
//  PlaySlider.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-20.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class PlaySlider: UISlider {

    let trackHeight: CGFloat = 3.0;
    
    public var index: Int?
    
    public var playing: Bool = false {
        didSet {
            if playing {
//                presentForPlaying()
            } else {
//                presentForPaused()
            }
        }
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.origin.y = bounds.size.height - trackHeight
        newBounds.size.height = trackHeight
        return newBounds
    }

}
