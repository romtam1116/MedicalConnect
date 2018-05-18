//
//  SignUpViewController.swift
//  MedicalConsult
//
//  Created by Roman on 2/20/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class SignUpViewController: BaseViewController {
    
    @IBOutlet var tfName: ACFloatingTextfield!
    @IBOutlet var tfEmail: ACFloatingTextfield!
    @IBOutlet var tfPassword: ACFloatingTextfield!
    @IBOutlet var tfConfirm: ACFloatingTextfield!
    @IBOutlet var btnSignup: UIButton!
    @IBOutlet var pageControl: UIPageControl!
    
    var user: User? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Name
        self.tfName.placeholder = NSLocalizedString("First & Last Name", comment: "comment")
        
        // Email
        self.tfEmail.placeholder = NSLocalizedString("Email", comment: "comment")
        
        // Pasword
        self.tfPassword.placeholder = NSLocalizedString("Password", comment: "comment")
        
        // Pasword
        self.tfConfirm.placeholder = NSLocalizedString("Confirm Password", comment: "comment")
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let welcomeProfileVC = segue.destination as! WelcomeProfileViewController
        welcomeProfileVC.user = self.user
        
    }
    
}

extension SignUpViewController {

    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func onSignUp(sender: AnyObject) {
        
        // Check if all required fields are filled
        if self.tfName.text!.isEmpty || self.tfPassword.text!.isEmpty || self.tfConfirm.text!.isEmpty || self.tfEmail.text!.isEmpty {
            AlertUtil.showSimpleAlert(self, title: "Please fill in all fields", message: nil, okButtonTitle: "OK")
            return
        }
        
        // Check if email is valid
        if !StringUtil.isValidEmail(self.tfEmail.text!) {
            AlertUtil.showSimpleAlert(self, title: "Please enter a valid email address", message: nil, okButtonTitle: "OK")
            return
        }
        
        // Check if passwords match
        if self.tfPassword.text! != self.tfConfirm.text! {
            AlertUtil.showSimpleAlert(self, title: "Yikes! The passwords you've entered don't match.", message: nil, okButtonTitle: "OK")
            return
        }
        
        self.user = User(fullName: self.tfName.text!, email: self.tfEmail.text!, password: self.tfPassword.text!)
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectWelcomeProfile, sender: nil)
        
    }
    
    @IBAction func onLogin(sender: AnyObject) {
        
        self.onBack(sender: nil)
        
    }

}
