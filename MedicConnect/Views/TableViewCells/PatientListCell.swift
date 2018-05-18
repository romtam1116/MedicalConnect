//
//  PatientListCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class PatientListCell: UITableViewCell {

    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    // Labels
    @IBOutlet var lblPatientName: UILabel!
    @IBOutlet var lblDoctorName: UILabel!
    @IBOutlet var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func setData(_ patient: Patient) {
        // Set data
        self.lblPatientName.text = "\(patient.name) #\(patient.patientNumber)"
        self.lblDoctorName.text = "\(patient.user.fullName)"
        self.lblDate.text = patient.getFormattedDate().replacingOccurrences(of: ",", with: "")
        
        self.imgUserPhoto.image = nil
        if let _user = patient.user as User? {
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgUserPhoto.af_setImage(withURL: imgURL)
            } else {
                self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                            text: _user.getInitials(),
                                                                                            font: UIFont(name: "Avenir-Book", size: 14)!,
                                                                                            size: CGSize(width: 30, height: 30))
            }
        }
    }

}
