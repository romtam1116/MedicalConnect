//
//  BaseViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/21/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    @IBOutlet weak var viewNotificationAlert: UIView!
    
    @IBOutlet weak var constOfNavigationTop: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Update layout for iPhone X
        if UIScreen.main.nativeBounds.height == 2436 && self.constOfNavigationTop != nil {
            self.constOfNavigationTop.constant = 24
        }
        
        // Observe new notification alert
        NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationIcon), name: NSNotification.Name(rawValue: NewNotificationAlertDidChangeNotification), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateNotificationIcon()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: General Message Alert
    
    @objc func updateNotificationIcon() {
        // Show/Hide new notification mark
        if self.viewNotificationAlert != nil {
            self.viewNotificationAlert.isHidden = !NotificationUtil.hasNewNotification
        }
    }

    // MARK: General Message Alert
    
    func showAlertMessage(title: String, message: String, buttonTitle: String, completion: @escaping (_ result: Bool) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: {
            (alert: UIAlertAction!) in
            completion(true)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "comment"), style: .default, handler: {
            (alert: UIAlertAction!) in
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showErrorMessage(title: String, message: String, buttonTitle: String, completion: @escaping (_ result: Bool) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: {
            (alert: UIAlertAction!) in
            completion(true)
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    // MARK: IBActions
    
    @IBAction func onNotifications(sender: AnyObject) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NotificationVC")
        
        self.gotoNextViewController(vc: vc)
        
    }
    
    @IBAction func onSearch(sender: AnyObject) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchVC")
        
        self.gotoNextViewController(vc: vc)
    }
    
    @IBAction func onSettings(sender: AnyObject) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsVC")
        
        self.gotoNextViewController(vc: vc)
        
    }
    
    @IBAction func onInvite(sender: AnyObject) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InvitePopupVC")
        
        self.gotoNextViewController(vc: vc)
    }
    
    // MARK: Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Add-On
    
    func gotoNextViewController(vc: UIViewController) {
        if (self.navigationController != nil) {
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    func dismissVC() {
        if (self.navigationController != nil) {
            _ = self.navigationController?.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func clearAllData() {
        UIApplication.shared.unregisterForRemoteNotifications()
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.tabBarController = nil
        delegate?.disableSinchClient()
        
        // Update user availability
        delegate?.shouldReceiveCall = false
        
        UserController.Instance.eraseUser()
        UserController.Instance.setRecommedendUsers([])
        UserController.Instance.setAvatarImg(nil)
        PostController.Instance.setFollowingPosts([])
        PostController.Instance.setRecommendedPosts([])
        PostController.Instance.setHashtagPosts([])
        PostController.Instance.setTrendingHashtags([])
        PostController.Instance.setPatientNotes([])
        CommentController.Instance.setComments([])
        LikeController.Instance.setPostLikes([])
        NotificationController.Instance.setNotifications([])
        NotificationController.Instance.setAnimatedNotifIDs([])
        PatientController.Instance.setPatients([])
        UserDefaultsUtil.DeleteToken()
        UserDefaultsUtil.DeleteUserId()
    }
}

