//
//  ImageHelper.swift
//  MedicalConsult
//
//  Created by Roman on 11/26/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import CoreGraphics
import AFImageHelper

class ImageHelper {

    class func circleImageWithBackgroundColorAndText(backgroundColor: UIColor, text: String, font: UIFont, size: CGSize) -> UIImage {
        
        return UIImage(text: text, font: font, color: UIColor.white, backgroundColor: backgroundColor, size: size, offset: CGPoint.zero)?.roundCornersToCircle() as UIImage? ?? UIImage()
        
    }

    class func captureView() -> UIImage {
        
        // Create graphics context with screen size
        let screenRect: CGRect = UIScreen.main.bounds
        UIGraphicsBeginImageContext(screenRect.size)
        if let _ctx = UIGraphicsGetCurrentContext() as CGContext? {
            UIColor.black.set()
            _ctx.fill(screenRect)
            
            // Grab reference to our window
            let window = UIApplication.shared.keyWindow
            
            // Transfer content into out context
            window?.layer.render(in: _ctx)
            if let _screenGrab = UIGraphicsGetImageFromCurrentImageContext() as UIImage? {
                UIGraphicsEndImageContext()
                return _screenGrab
            } else {
                print("Cannot capture view")
                return UIImage()
            }
        } else {
            print("Cannot capture view")
            return UIImage()
        }
        
    }
}
