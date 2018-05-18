//
//  SplashViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-11.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkUser() {
        
        if !UserDefaultsUtil.LoadToken().isEmpty {
            
            UserService.Instance.getMe(completion: {
                (user: User?) in
                if let _user = user as User? {
                    // User logged in
                    UserController.Instance.setUser(_user)
                    
                    UserDefaultsUtil.SaveUserId(userid: (user?.id)!)
                    NotificationUtil.makeUserNotificationEnabled()
                    
                    // Configure VOIP and sinch client
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.voipRegistration()
                    appDelegate.configureSinchClient(_user.id)
                    
                    // Update user availability
                    appDelegate.shouldReceiveCall = true
                    
                    self.performSegue(withIdentifier: Constants.SegueMedicConnectHome, sender: nil)
                } else {
                    // User not logged in properly
                    UserDefaultsUtil.DeleteUserId()
                    self.performSegue(withIdentifier: Constants.SegueMedicConnectSignIn, sender: nil)
                }
            })
            
        } else {
            // User not logged in
            UserDefaultsUtil.DeleteUserId()
            self.performSegue(withIdentifier: Constants.SegueMedicConnectSignIn, sender: nil)
        }
        
    }

}
