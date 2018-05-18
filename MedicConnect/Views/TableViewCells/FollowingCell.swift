//
//  FollowingCell.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class FollowingCell: UITableViewCell {
    
    // Buttons
    @IBOutlet var btnFavorite: TVButton!
    @IBOutlet var btnMessage: TVButton!
    @IBOutlet var btnAction: TVButton!
    
    // Labels
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var lblUserLocation: UILabel!
    @IBOutlet var lblUserTitle: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    // MARK: Set Data
    
    func setFollowData(user: User, showFollowingStatus: Bool = true) {
        
        guard (UserController.Instance.getUser() as User?) != nil else {
            return
        }
        
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                       text: user.getInitials(),
                                                                                       font: UIFont(name: "Avenir-Book", size: 20)!,
                                                                                       size: CGSize(width: 44, height: 44))
        }
        
        // Customize User Data
        self.lblUserName.text = user.fullName
        self.lblUserTitle.text = user.title
        self.lblUserLocation.text = user.location
        
    }
    
}
