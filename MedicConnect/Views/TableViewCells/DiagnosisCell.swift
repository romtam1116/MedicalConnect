//
//  DiagnosisCell.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-01-18.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import UIKit
import AlamofireImage
import Sheriff

class DiagnosisCell: UITableViewCell {
    
    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    
    // Buttons
    @IBOutlet var btnLike: TVButton!
    @IBOutlet var btnMessage: TVButton!
    @IBOutlet var btnShare: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    @IBOutlet var btnSpeaker: UIButton!
    
    // BadgeViews
    @IBOutlet var likeBadgeView: GIBadgeView!
    @IBOutlet var commentBadgeView: GIBadgeView!
    
    // Constraints
    @IBOutlet var constOfLblDateBottom: NSLayoutConstraint!
    @IBOutlet var constOfTxtVHashtagsTop: NSLayoutConstraint!
    @IBOutlet var constOfTxtVHashtagsHeight: NSLayoutConstraint!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblLikedDescription: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // TextView
    @IBOutlet weak var txtVHashtags: UITextView!
    
    // Slider
    @IBOutlet weak var playSlider: PlaySlider!
    
    // Fonts
    let likeBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)
    let commentBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)
    let appendAttributes = [ NSAttributedStringKey.foregroundColor : UIColor.lightGray, NSAttributedStringKey.font : UIFont(name: "Avenir-Heavy", size: 13.0) as UIFont? ?? UIFont.systemFont(ofSize: 13.0) ]
    
    // Expand/Collpase
    var isExpanded: Bool = false {
        didSet {
            if !isExpanded {
                self.clipsToBounds = true
                
                self.constOfLblDateBottom.constant = 4
                self.btnLike.isHidden = true
                self.btnMessage.isHidden = true
                self.btnShare.isHidden = true
                self.lblLikedDescription.isHidden = true
                self.txtVHashtags.isHidden = true
                self.btnSpeaker.isHidden = true
                self.btnPlay.isHidden = true
                self.btnBackward.isHidden = true
                self.btnForward.isHidden = true
                self.lblElapsedTime.isHidden = true
                self.lblDuration.isHidden = true
                self.playSlider.isHidden = true
                
            } else {
                self.clipsToBounds = false
                
                let constraintRect = CGSize(width: self.txtVHashtags.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.txtVHashtags.text == "" ? CGRect.zero : self.txtVHashtags.text!.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.txtVHashtags.font!], context: nil)
                
                self.constOfTxtVHashtagsHeight.constant = self.txtVHashtags.text == "" ? ceil(boundingBox.height) : ceil(boundingBox.height) + 16.0
                self.constOfLblDateBottom.constant = self.constOfTxtVHashtagsHeight.constant + 48 + 65
                
                self.btnSpeaker.setImage(UIImage(named: AudioHelper.overrideMode == .speaker ? "icon_speaker_on" : "icon_speaker_off"), for: .normal)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.btnLike.isHidden = false
                    self.btnMessage.isHidden = false
                    self.btnShare.isHidden = false
                    self.lblLikedDescription.isHidden = false
                    self.txtVHashtags.isHidden = false
                    self.btnSpeaker.isHidden = false
                    self.btnPlay.isHidden = false
                    self.btnBackward.isHidden = false
                    self.btnForward.isHidden = false
                    self.lblElapsedTime.isHidden = false
                    self.lblDuration.isHidden = false
                    self.playSlider.isHidden = false
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Slider
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .normal)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .highlighted)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .selected)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if self.likeBadgeView != nil {
            self.likeBadgeView.removeFromSuperview()
            self.likeBadgeView = nil
        }
        
        if self.commentBadgeView != nil {
            self.commentBadgeView.removeFromSuperview()
            self.commentBadgeView = nil
        }
        
    }
    
    func setData(post: Post) {
        
        // Set Broadcast Label
        self.lblBroadcast.text = post.title
        
        // Set Doctor Name
        self.lblUsername.text = "\(post.user.fullName)"
        
        // Set date label
        self.lblDate.text = post.getFormattedDate()
        
        // Set like description label
        if let likeDescription = post.likeDescription as String?, !likeDescription.isEmpty {
            let blackFont: UIFont = UIFont(name: "Avenir-Black", size: 11.0) as UIFont? ?? UIFont.systemFont(ofSize: 11.0)
            let bookFont: UIFont = UIFont(name: "Avenir-Book", size: 11.0) as UIFont? ?? UIFont.systemFont(ofSize: 11.0)
            
            let nsText = likeDescription as NSString
            let textRange = NSMakeRange(0, nsText.length)
            let attributedString = NSMutableAttributedString(string: likeDescription, attributes: [NSAttributedStringKey.font : blackFont])
            
            nsText.enumerateSubstrings(in: textRange, options: .byWords, using: {
                (substring, substringRange, _, _) in
                if (substring == "Liked" || substring == "by" || substring == "and") {
                    attributedString.addAttribute(NSAttributedStringKey.font, value: bookFont, range: substringRange)
                }
            })
            
            self.lblLikedDescription.attributedText = attributedString
            
        } else {
            self.lblLikedDescription.text = "Liked by 0 users"
        }
        
        // Customize badge
        if self.likeBadgeView == nil {
            self.likeBadgeView = GIBadgeView()
            //self.likeBadgeView.setMinimumSize(10.0)
            self.likeBadgeView.font = likeBadgeViewFont
            self.likeBadgeView.textColor = Constants.ColorDarkGray2
            self.likeBadgeView.backgroundColor = UIColor.white
            self.likeBadgeView.topOffset = 26.0
            self.likeBadgeView.rightOffset = 11.0
            self.btnLike.addSubview(self.likeBadgeView)
            
            let tapGestureOnLikeBadge = UITapGestureRecognizer(target: self, action: #selector(LikeBadgeTapped))
            likeBadgeView.addGestureRecognizer(tapGestureOnLikeBadge)
        }
        
        self.likeBadgeView.badgeValue = post.likes.count
        
        if self.commentBadgeView == nil {
            self.commentBadgeView = GIBadgeView()
            //commentBadgeView(10.0)
            self.commentBadgeView.font = commentBadgeViewFont
            self.commentBadgeView.textColor = Constants.ColorDarkGray2
            self.commentBadgeView.backgroundColor = UIColor.white
            self.commentBadgeView.topOffset = 26.0
            self.commentBadgeView.rightOffset = 11.0
            self.btnMessage.addSubview(self.commentBadgeView)
            
            let tapGestureOnCommentBadge = UITapGestureRecognizer(target: self, action: #selector(CommentsBadgeTapped))
            commentBadgeView.addGestureRecognizer(tapGestureOnCommentBadge)
        }
        
        self.commentBadgeView.badgeValue = post.commentsCount
        
        // Set hashtags textview
        self.txtVHashtags.text = post.hashtags.count > 0 ? post.hashtags.joined(separator: " ") : ""
        
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
        
    }
    
}

extension DiagnosisCell {
    @objc func LikeBadgeTapped() {
        btnLike.sendActions(for: .touchUpInside)
    }
    
    @objc func CommentsBadgeTapped() {
        btnMessage.sendActions(for: .touchUpInside)
    }
}
