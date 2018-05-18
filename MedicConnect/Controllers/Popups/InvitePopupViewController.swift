//
//  InvitePopupViewController.swift
//  MedicalConsult
//
//  Created by Roman on 1/12/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import MessageUI

let inviteTitle = "Check Out This New App"
let inviteText = "Hey, I'm trying this new Audio Social App called Medic Connect, tap the link below and sign up to Beta Test it with me!"
let inviteURL = "https://www.codiapp.com"

class InvitePopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var btnFacebook: UIButton!
    @IBOutlet var btnTwitter: UIButton!
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

extension InvitePopupViewController {
    
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        
        self.dismissVC()
    }
    
    
    @IBAction func onCancel(sender: UIButton!) {
        
        self.onClose(sender: nil)
    }
    
    @IBAction func onFacebook(sender: UIButton!) {
        
    }
    
    @IBAction func onTwitter(sender: UIButton!) {
        
    }
    
    @IBAction func onEmail(sender: UIButton!) {
        
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.setSubject(inviteTitle)
        composeVC.setMessageBody("\(inviteText)<br><br>\(inviteURL)", isHTML: true)
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func onMessage(sender: UIButton!) {
        
        if !MFMessageComposeViewController.canSendText() {
            print("Mail services are not available")
            return
        }
        
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.body = "\(inviteText)  \(inviteURL)"
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
}

extension InvitePopupViewController: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension InvitePopupViewController: MFMessageComposeViewControllerDelegate {
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
}

