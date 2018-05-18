//
//  NotificationListCell.swift
//  MedicalConsult
//
//  Created by Roman on 12/20/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class NotificationListCell: UITableViewCell {
    
    @IBOutlet var viewBlink: UIView!
    @IBOutlet var imgUserPhoto: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var btnFollowing: TVButton!
    @IBOutlet var btnUnFollow: TVButton!
    @IBOutlet var btnRequested: TVButton!
    @IBOutlet var btnAccept: TVButton!
    @IBOutlet var btnDecline: TVButton!
    
    @IBOutlet weak var lbcDescriptionMarginToRight: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set button border colors
        self.imgUserPhoto.layer.borderColor = UIColor.init(red: 116/255.0, green: 183/255.0, blue: 191/255.0, alpha: 1.0).cgColor
        self.btnFollowing.layer.borderColor = UIColor.init(red: 150/255.0, green: 155/255.0, blue: 168/255.0, alpha: 1.0).cgColor
        self.btnRequested.layer.borderColor = UIColor.init(red: 28/255.0, green: 48/255.0, blue: 58/255.0, alpha: 1.0).cgColor
        self.btnDecline.layer.borderColor = UIColor.init(red: 183/255.0, green: 184/255.0, blue: 186/255.0, alpha: 1.0).cgColor
        
        // Disable requested button
        self.btnRequested.isUserInteractionEnabled = false
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
    func setNotificationData(notification: Notification) {
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
//        self.backgroundColor = notification.isRead == 0 ? UIColor.red : UIColor.white
        self.viewBlink.alpha = 0
        if notification.isRead == 0 && !NotificationController.Instance.checkIfAnimated(notification.id) {
            NotificationController.Instance.addAnimatedNotifID(notification.id)
            
            // Show Blinking animation
            UIView.animate(withDuration: 0.3, animations: {
                self.viewBlink.alpha = 1.0
            }) { (success) in
                UIView.animate(withDuration: 0.3, delay: 0.5, options: UIViewAnimationOptions(rawValue: 0), animations: {
                    self.viewBlink.alpha = 0
                }, completion: { (success) in
                    
                })
            }
        }
        
        self.btnFollowing.isHidden = true
        self.btnUnFollow.isHidden = true
        self.btnRequested.isHidden = true
        self.btnAccept.isHidden = true
        self.btnDecline.isHidden = true
        
        if let _url = notification.fromUser.photo as String?,
            let imgURL = URL(string: _url) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                        text: notification.fromUser.getInitials(),
                                                                                        font: UIFont(name: "Avenir-Book", size: 18)!,
                                                                                        size: CGSize(width: 40, height: 40))
        }
        
        self.lblUsername.text = notification.fromUser.fullName
        self.lblDescription.text = notification.message
        self.lblTime.text = notification.getFormattedDate()
        
        // Customize Data
        if notification.notificationType == .like {
            
            self.lbcDescriptionMarginToRight.constant = -100
            
        } else if notification.notificationType == .comment {
            
            self.lbcDescriptionMarginToRight.constant = -100
            
        } else if notification.notificationType == .broadcast {

            self.lbcDescriptionMarginToRight.constant = -100
            
        } else if notification.notificationType == .newFollower {
            
            self.btnRequested.isHidden = (_user.id == notification.fromUser.id) || !(_user.requesting as! [User]).contains(where: { $0.id == notification.fromUser.id })
            
            if (self.btnRequested.isHidden) {
                self.btnFollowing.isHidden = (_user.id == notification.fromUser.id) || !(_user.following as! [User]).contains(where: { $0.id == notification.fromUser.id })
                self.btnUnFollow.isHidden = (_user.id == notification.fromUser.id) || (_user.following as! [User]).contains(where: { $0.id == notification.fromUser.id })
            }
            
            self.lbcDescriptionMarginToRight.constant = 10
            
        } else if notification.notificationType == .followRequest {
            
            if let tmpArr = _user.requested as? [User] {
                self.btnAccept.isHidden = !tmpArr.contains(where: {$0.id == notification.fromUser.id})
                self.btnDecline.isHidden = !tmpArr.contains(where: {$0.id == notification.fromUser.id})
                
                self.lbcDescriptionMarginToRight.constant = self.btnAccept.isHidden ? -100 : 47
            }
            
            if (self.btnAccept.isHidden) {
                self.lbcDescriptionMarginToRight.constant = 10
                
                self.btnRequested.isHidden = (_user.id == notification.fromUser.id) || !(_user.requesting as! [User]).contains(where: { $0.id == notification.fromUser.id })
                
                if (self.btnRequested.isHidden) {
                    self.btnFollowing.isHidden = (_user.id == notification.fromUser.id) || !(_user.following as! [User]).contains(where: { $0.id == notification.fromUser.id })
                    self.btnUnFollow.isHidden = (_user.id == notification.fromUser.id) || (_user.following as! [User]).contains(where: { $0.id == notification.fromUser.id })
                }
            } else {
                self.lbcDescriptionMarginToRight.constant = 47
            }
            
        } else {
            
            self.lbcDescriptionMarginToRight.constant = -100

        }
        
    }
    
}
