//
//  CommentsListCell.swift
//  MedicalConsult
//
//  Created by Roman on 12/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class CommentsListCell: UITableViewCell {
    
    @IBOutlet var imgUserPhoto: RadAvatar!
    @IBOutlet var lblAuthor: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblComment: UILabel!
    
    func setCellWithAuthor(url: String, author: String, date: String, comment: String) {
        
        self.selectionStyle = UITableViewCellSelectionStyle.default
        
        self.lblAuthor.text = author
        self.lblDate.text = date
        self.lblComment.text = comment
        
        if let imgURL = URL(string: url) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
//            self.imgUserPhoto.af_setImage(withURL: imgURL, placeholderImage: ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: Constants.ColorOrange, text: "KM", font: font, size: CGSize(width: 40, height: 40)))
        }
        
    }
    
}
