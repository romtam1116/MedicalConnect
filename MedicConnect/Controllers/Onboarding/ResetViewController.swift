//
//  ResetViewController.swift
//  MedicalConsult
//
//  Created by Roman Zoffoli on 27/02/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class ResetViewController: BaseViewController {
    
    @IBOutlet var txFieldEmail: ACFloatingTextfield!
    @IBOutlet var btnSend: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Email
        self.txFieldEmail.placeholder = NSLocalizedString("Email", comment: "comment")
    }
    
    //MARK: - UI Actions
    @IBAction func resetPassword() {
        
        if let email = self.txFieldEmail.text as String? {
            
            if email.isEmpty {
                AlertUtil.showSimpleAlert(self, title: "Please enter email address.", message: nil, okButtonTitle: "OK")
                return
            }
            if !StringUtil.isValidEmail(email) {
                AlertUtil.showSimpleAlert(self, title: "Please enter valid email address.", message: nil, okButtonTitle: "OK")
                return
            }
            
            self.btnSend.isEnabled = false
            
            let token = StringUtil.randomString(length: 12)
            
            UserService.Instance.forgotPassword(email: email, token: token, completion: {
                (success: Bool, code: Int?) in
                
                self.btnSend.isEnabled = true
                
                if success {
                    AlertUtil.showOKAlert(self, message: "An email has been sent\nwith a link to reset your password.",  okCompletionBlock: {
                        UserDefaultsUtil.SaveForgotPasswordToken(token: token)
                        _ = self.navigationController?.popViewController(animated: false)
                    })
                } else {
                    if code == 404 {
                        AlertUtil.showSimpleAlert(self, title: "The email address you entered\nis not associated with an account.", message: nil, okButtonTitle: "TRY AGAIN")
                    } else {
                        AlertUtil.showSimpleAlert(self, title: "Something went wrong on server. Please contact administrator.", message: nil, okButtonTitle: "OK")
                    }
                }
                
            })
        }
        
    }
    
    @IBAction func dismiss() {
        
        _ = self.navigationController?.popViewController(animated: false)
        
    }
}
