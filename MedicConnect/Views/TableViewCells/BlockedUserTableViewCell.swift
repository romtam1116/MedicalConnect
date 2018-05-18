//
//  BlockedUserTableViewCell.swift
//  MedicalConsult
//
//  Created by Voltae Saito on 7/3/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import AlamofireImage


class BlockedUserTableViewCell: UITableViewCell {

    @IBOutlet weak var m_userImage: UIImageView!
    @IBOutlet weak var m_userName: UILabel!
    @IBOutlet weak var m_userDescription: UILabel!
    @IBOutlet weak var m_playCount: UILabel!
    @IBOutlet weak var m_btnBlock: UIButton!
    
    let placeholderImageFont = UIFont(name: "Avenir-Heavy", size: 25.0) as UIFont? ?? UIFont.systemFont(ofSize: 25.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(user: User) {
        
        if let imgURL = URL(string: user.photo) as URL? {
            self.m_userImage.af_setImage(withURL: imgURL)
        } else {
            self.m_userImage.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                     text: user.getInitials(),
                                                                                     font: UIFont(name: "Avenir-Book", size: 24)!,
                                                                                     size: CGSize(width: 60, height: 60))
        }
        
        m_userName.text = user.fullName
        m_userDescription.text = user.title
        
    }

}
