//
//  SearchPeopleCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-09.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class SearchPeopleCell: UITableViewCell {
    
    // Labels
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblUserDescription: UILabel!
    @IBOutlet var lblUserplays: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    var placeholderImage: UIImage?
    
    // Fonts
    let avatarFont = UIFont(name: "Avenir-Heavy", size: 15.0) as UIFont? ?? UIFont.systemFont(ofSize: 15.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.placeholderImage = nil
    }
    
    // MARK: Set Data
    
    func setPeopleData(user: User) {
        
        // Customize Avatar
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                         text: user.getInitials(),
                                                                                         font: UIFont(name: "Avenir-Book", size: 24)!,
                                                                                         size: CGSize(width: 52, height: 52))
        }
        
        // Customize User Data
        self.lblUsername.text = user.fullName
        self.lblUserDescription.text = user.title
        
    }
    
}
