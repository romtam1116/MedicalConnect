//
//  SharePopupViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class SharePopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var tvCaption: UITextView!
    @IBOutlet var btnEmail: UIButton!
    @IBOutlet var btnMessage: UIButton!
    
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
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    //MARK: Initialize Views
    
    func initViews() {
    
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
    }
    
}

extension SharePopupViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }

    }

    
    @IBAction func onSocialButtonSelect(sender: UIButton!) {
        
        sender.isSelected = !sender.isSelected
        
    }
    
    @IBAction func onCancel(sender: UIButton!) {
        
        self.onClose(sender: nil)
        
    }
    
    @IBAction func onShare(sender: UIButton!) {
        
        self.onClose(sender: nil)
        
    }

}
