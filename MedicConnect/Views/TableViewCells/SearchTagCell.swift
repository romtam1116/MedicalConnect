//
//  SearchTagCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-09.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class SearchTagCell: UITableViewCell {

    // Labels
    @IBOutlet var lblHashtag: UILabel!
    @IBOutlet var lblBroadcastCount: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: Set Data
    
    func setHashtagData(hashtag: String) {
        // Customize Hashtag Data
        
        self.lblHashtag.text = hashtag
        self.lblBroadcastCount.text = "128 broadcasts"
        
    }
    
}
