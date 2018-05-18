//
//  CallHistoryAudioCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class CallHistoryAudioCell: UITableViewCell {
    
    // Labels
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var imgType: UIImageView!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    // MARK: Set Data
    
    func setUserData(user: [String: String], isAudio: Bool) {
        
        guard (UserController.Instance.getUser() as User?) != nil else {
            return
        }
        
        if user["photoURL"] != nil,
            let imgURL = URL(string: user["photoURL"]!) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 149/255.0, green: 208/255.0, blue: 206/255.0, alpha: 1.0),
                                                                                        text: user["initial"]!,
                                                                                        font: UIFont(name: "Avenir-Book", size: 18)!,
                                                                                        size: CGSize(width: 44, height: 44))
        }
        
        // Customize User Data
        self.lblUserName.text = user["name"]
        self.lblDate.text = user["date"]
        self.imgType.image = UIImage.init(named: isAudio ? "icon_history_audio" : "icon_history_video")
        
    }
    
}
