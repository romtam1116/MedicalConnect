//
//  PatientNotesCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-20.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

protocol PatientNotesCellDelegate : class {
    func patientNotesCellDidTapReferringUser(_ user: User)
}

class PatientNotesCell: UITableViewCell {

    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Buttons
    @IBOutlet var btnSynopsis: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    @IBOutlet var btnSpeaker: UIButton!
    
    // Labels
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDoctorName: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // Container View
    @IBOutlet var viewDoctors: UIView!
    @IBOutlet var ivCreator: UIImageView!
    
    // Slider
    @IBOutlet weak var playSlider: PlaySlider!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfImageAvatarBottom: NSLayoutConstraint!
    @IBOutlet var constOfDocsViewWidth: NSLayoutConstraint!
    @IBOutlet var constOfDocsViewFirstLeading: NSLayoutConstraint!
    @IBOutlet var constOfDocsViewCenterX: NSLayoutConstraint!
    @IBOutlet var constOfBtnPlayTop: NSLayoutConstraint!
    
    weak var delegate: PatientNotesCellDelegate?
    
    var postDescription: String = ""
    var referringUsers: [User] = []
    var postUser: User? = nil
    
    // Expand/Collpase
    var isExpanded:Bool = false {
        didSet {
            if !isExpanded {
                self.clipsToBounds = true
                
                self.lblDescription.numberOfLines = 1
                self.lblDescription.shouldExpand = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = true
                
                self.constOfImageAvatarBottom.constant = 20
                self.constOfLblDescriptionHeight.constant = 21
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.viewDoctors.alpha = 0
                    self.btnSpeaker.alpha = 0
                    self.btnPlay.alpha = 0
                    self.btnBackward.alpha = 0
                    self.btnForward.alpha = 0
                    self.lblElapsedTime.alpha = 0
                    self.lblDuration.alpha = 0
                    self.playSlider.alpha = 0
                }, completion: { (success) in
                    self.constOfDocsViewWidth.constant = 88
                    self.constOfDocsViewFirstLeading.constant = 24
                    self.constOfDocsViewCenterX.constant = 12
                })
                
            } else {
                self.clipsToBounds = false
                
                let constRect = CGSize(width: self.lblDescription.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundBox = self.postDescription.boundingRect(with: constRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.lblDescription.font], context: nil)
                self.constOfLblDescriptionHeight.constant = ceil(boundBox.height)
                self.lblDescription.shouldCollapse = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = false
                
                self.constOfImageAvatarBottom.constant = 69 + self.constOfBtnPlayTop.constant
                
                self.btnSpeaker.setImage(UIImage(named: AudioHelper.overrideMode == .speaker ? "icon_speaker_on" : "icon_speaker_off"), for: .normal)
                
                UIView.animate(withDuration: 0.7, animations: {
                    self.viewDoctors.alpha = 1
                    self.btnSpeaker.alpha = 1
                    self.btnPlay.alpha = 1
                    self.btnBackward.alpha = 1
                    self.btnForward.alpha = 1
                    self.lblElapsedTime.alpha = 1
                    self.lblDuration.alpha = 1
                    self.playSlider.alpha = 1
                })
                
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.lblDescription.numberOfLines = 0
//                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide bottom controls
        self.viewDoctors.alpha = 0
        self.btnSpeaker.alpha = 0
        self.btnPlay.alpha = 0
        self.btnBackward.alpha = 0
        self.btnForward.alpha = 0
        self.lblElapsedTime.alpha = 0
        self.lblDuration.alpha = 0
        self.playSlider.alpha = 0
        
        let tapGestureOnUserAvatars = UITapGestureRecognizer(target: self, action: #selector(onTapUsers(sender:)))
        self.viewDoctors.addGestureRecognizer(tapGestureOnUserAvatars)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Referring Doctor images
        for view in self.viewDoctors.subviews {
            if view.tag >= 100 {
                let imgView: UIImageView = view.viewWithTag(200) as! UIImageView
                imgView.layer.borderWidth = 1.0
                imgView.layer.borderColor = UIColor.init(red: 107/255.0, green: 199/255.0, blue: 213/255.0, alpha: 1.0).cgColor
            } else if view is UIImageView {
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.init(red: 107/255.0, green: 199/255.0, blue: 213/255.0, alpha: 1.0).cgColor
            }
        }
        
        // Slider
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .normal)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .highlighted)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .selected)
        
        // Spinning Circle
        self.ivProgressCircle.loadGif(name: "progress_circle")
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.lblDescription.collapsed = true
        self.lblDescription.text = nil
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
    func setData(post: Post) {
        // Set Patient Note Info
        self.lblDoctorName.text = post.user.fullName
        self.lblDate.text = post.getFormattedDate()
        self.postDescription = post.descriptions
        
        // Customize Avatar
        self.imgUserAvatar.image = nil
        if let imgURL = URL(string: post.user.photo) as URL? {
            self.imgUserAvatar.af_setImage(withURL: imgURL)
        } else {
            self.imgUserAvatar.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                         text: post.user.getInitials(),
                                                                                         font: UIFont(name: "Avenir-Book", size: 14)!,
                                                                                         size: CGSize(width: 30, height: 30))
        }
        
        if post.orderNumber == "" {
            self.btnSynopsis.isHidden = true
            self.ivProgressCircle.isHidden = true
            
        } else {
            self.btnSynopsis.isHidden = false
            
            if post.transcriptionUrl == "" {
                self.btnSynopsis.setImage(UIImage.init(named: "icon_transcription_inactive"), for: .normal)
                self.ivProgressCircle.isHidden = false
            } else {
                self.btnSynopsis.setImage(UIImage.init(named: "icon_transcription_active"), for: .normal)
                self.ivProgressCircle.isHidden = true
            }
        }
        
        // Show referring doctors' images
        self.constOfBtnPlayTop.constant = post.referringUsers.count == 0 ? 18 : 46
        self.viewDoctors.isHidden = post.referringUsers.count == 0 ? true : false
        self.referringUsers = post.referringUsers
        
        self.postUser = post.user
        
        if let imgURL = URL(string: post.user.photo) as URL? {
            self.ivCreator.af_setImage(withURL: imgURL)
        } else {
            self.ivCreator.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                     text: post.user.getInitials(),
                                                                                     font: UIFont(name: "Avenir-Book", size: 13)!,
                                                                                     size: CGSize(width: 30, height: 30))
        }
        
        for index in 0...2 {
            if let view = self.viewDoctors.viewWithTag(index + 100) {
                if index < post.referringUsers.count {
                    view.isHidden = false
                    
                    if let imgView = view.viewWithTag(200) as? UIImageView {
                        let user = post.referringUsers[index]
                        if let imgURL = URL(string: user.photo) as URL? {
                            imgView.af_setImage(withURL: imgURL)
                        } else {
                            imgView.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                              text: user.getInitials(),
                                                                                              font: UIFont(name: "Avenir-Book", size: 13)!,
                                                                                              size: CGSize(width: 30, height: 30))
                        }
                    }
                    
                } else {
                    view.isHidden = true
                }
            }
        }
    }
    
    // MARK: Tap Gesture
    
    @objc func onTapUsers(sender: UITapGestureRecognizer) {
        if self.constOfDocsViewWidth.constant == 180 {
            // Already expanded
            let view = sender.view
            let loc = sender.location(in: view)
            if let subview = view?.hitTest(loc, with: nil) {
                if subview.tag >= 100 {
                    let user = self.referringUsers[subview.tag - 100]
                    delegate?.patientNotesCellDidTapReferringUser(user)
                } else if subview.tag == 99 {
                    delegate?.patientNotesCellDidTapReferringUser(self.postUser!)
                }
            }
            
        } else {
            // Expand Referring Doctor images
            self.constOfDocsViewWidth.constant = 180
            self.constOfDocsViewFirstLeading.constant = 54
            self.constOfDocsViewCenterX.constant = 27
            UIView.animate(withDuration: 0.3, animations: {
                self.contentView.layoutIfNeeded()
            }) { (success) in
                // self.viewDoctors.isUserInteractionEnabled = false
            }
        }
    }
    
}
