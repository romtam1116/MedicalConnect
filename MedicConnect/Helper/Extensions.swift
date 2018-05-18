//
//  Extensions.swift
//  MedicalConsult
//
//  Created by Roman on 2/20/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import Foundation

extension NSMutableData {
    func append(string: String) {
        let data = string.data(
            using: String.Encoding.utf8,
            allowLossyConversion: true)
        append(data!)
    }
}

extension String {
    
    func sha1() -> String {
        
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
        
    }
    
    func fromBase64() -> String? {
        
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
        
    }
    
    func toBase64() -> String {
        
        return Data(self.utf8).base64EncodedString()
        
    }
    
}

extension UITextField {
    
    func useUnderline(color: UIColor = UIColor.lightGray) {
        
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = color.cgColor
        border.frame = CGRect(origin: CGPoint(x: 0,y: self.frame.size.height - borderWidth), size: CGSize(width: self.frame.size.width, height: self.frame.size.height))
        border.borderWidth = borderWidth
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
        
    }
    
    func useImageIcon(image: UIImage) {
        
        let imgView = UIImageView(frame: CGRect(x: 0, y: 10, width: 24, height: 24))
        imgView.image = image
        
        self.addSubview(imgView)
        
    }
}

extension UITextView {
    
    func useImageIcon(image: UIImage) {
        
        let imgView = UIImageView(frame: CGRect(x: self.frame.width - 35, y: 10, width: 24, height: 24))
        imgView.image = image
        
        self.addSubview(imgView)
        
    }
}

extension UIButton {
    
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
    
    func setCornered(withBorder: Bool = true, borderWidth: CGFloat = 1.5) {
        
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        
        if withBorder {
            self.layer.borderColor = Constants.ColorDarkGray.cgColor
            self.layer.borderWidth = borderWidth
        }
        
    }
    
    func useBorder() {
        
        self.layer.cornerRadius = 25.0
        self.layer.borderColor = Constants.ColorDarkGray.cgColor
        self.layer.borderWidth = 2.0
        
    }
    
    func setCircle() {
        
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
        
    }
    
    func setCircleWithBorder(width: CGFloat = 2.0) {
        
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = width
        self.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
        
    }
    
    func useUnderline() {
        
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.lightGray.cgColor
        border.frame = CGRect(origin: CGPoint(x: 0,y: self.frame.size.height - borderWidth), size: CGSize(width: self.frame.size.width, height: self.frame.size.height))
        border.borderWidth = borderWidth
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
        
    }
    
    func useImageIcon(image: UIImage) {
        
        let imgView = UIImageView(frame: CGRect(x: self.frame.width - 48.0, y: self.frame.size.height / 2 - 12.0, width: 24, height: 24))
        imgView.image = image
        imgView.tag = 77
        self.insertSubview(imgView, at: 7)
        
    }
    
    func removeImageIcon() {
        
        let view = self.viewWithTag(77)
        view?.removeFromSuperview()
        
    }
    
    func makeEnabled(enabled: Bool) {
        self.isEnabled = enabled
        self.alpha = enabled ? 1.0 : 0.5
    }
    
}

extension UIImageView {
    
    func setCircle() {
        
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
        
    }
    
}

extension TimeInterval {
    var durationText:String {
        
        let hours:Int = Int(self.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(self.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(self.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%i:%02i", minutes, seconds)
        }
        
    }
}
