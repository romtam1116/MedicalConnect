//
//  ShareBroadcastViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/5/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

let NotificationDidRecordingFinish = "NotificationDidRecordingFinish"

class ShareBroadcastViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblQuestion: UILabel!
    
    @IBOutlet var btnEmail: UIButton!
    @IBOutlet var btnMessage: UIButton!
    @IBOutlet var btnDocument: UIButton!
    
    @IBOutlet var btnSkip: UIButton!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var viewYes: UIView!
    
    @IBOutlet var constOfPopupHeight: NSLayoutConstraint!
    
    var postId: String?
    var fromList: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    func initViews() {
        
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        // Record Description
        self.lblDescription.text = !fromList ? "You’ve successfully\nrecorded a new \(DataManager.Instance.getPostType().lowercased())." : ""
        
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis && !fromList) {
            // Diagnosis
            self.constOfPopupHeight.constant = 200
            self.lblQuestion.text = "Would you like to record\nanother diagnosis?"
            self.btnEmail.isHidden = true
            self.btnMessage.isHidden = true
            self.btnDocument.isHidden = true
            
        } else {
            // Consult or Patient Note
            self.constOfPopupHeight.constant = fromList ? 200 : 250
            self.lblQuestion.text = "Would you like to transcribe\nthis audio to a text document?"
            self.btnEmail.isHidden = true
            self.btnMessage.isHidden = true
            
        }
        
        // Buttons highlighted status
        self.btnSkip.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        self.btnYes.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
    
    }
}

extension ShareBroadcastViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = true
        
        if let _nav = self.navigationController as UINavigationController? {
            if DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis {
                _nav.popToRootViewController(animated: false)
            } else if fromList {
                _nav.popViewController(animated: false)
            } else {
                _nav.dismiss(animated: false, completion: nil)
            }
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onSocialButtonSelect(sender: UIButton!) {
        
        sender.isSelected = !sender.isSelected
        
    }
    
    @IBAction func onSkip(sender: UIButton) {
        if (DataManager.Instance.getPostType() != Constants.PostTypeNote && !fromList) {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationDidRecordingFinish), object: nil)
        }
        
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis) {
            // Diagnosis
            self.onClose(sender: sender)
        } else {
            // Consult or Patient Note
            self.onClose(sender: sender)
        }
    }
    
    @IBAction func onYes(sender: UIButton) {
        if (DataManager.Instance.getPostType() != Constants.PostTypeNote && !fromList) {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationDidRecordingFinish), object: nil)
        }
        
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis) {
            // Diagnosis
            self.onClose(sender: sender)
            
        } else {
            // Consult or Patient Note
            self.btnSkip.isEnabled = false
            self.btnYes.isEnabled = false
            
            PostService.Instance.placeOrder(postId: self.postId!, completion: { (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        DispatchQueue.main.async {
                            self.onClose(sender: sender)
                        }
                    })
                    
                } else {
                    DispatchQueue.main.async {
                        AlertUtil.showSimpleAlert(self, title: "Transcription failed. Please try again.", message: nil, okButtonTitle: "OK")
                        self.btnSkip.isEnabled = true
                        self.btnYes.isEnabled = true
                    }
                }
                
            })
        }
    }

}
