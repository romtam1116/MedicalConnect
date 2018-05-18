//
//  ResetPasswordViewController.swift
//  MedicalConsult
//
//  Created by El Capitan on 7/20/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class ResetPasswordViewController: BaseViewController {

    @IBOutlet weak var txtPassword: ACFloatingTextfield!
    @IBOutlet weak var txtConfirm: ACFloatingTextfield!
    @IBOutlet weak var btnReset: UIButton!
    
    public var token: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtPassword.placeholder = NSLocalizedString("New Password", comment: "comment")
        txtConfirm.placeholder = NSLocalizedString("Confirm Password", comment: "comment")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - UI Actions
    @IBAction func dismiss() {
        
        _ = self.navigationController?.popViewController(animated: false)
        
    }
    
    @IBAction func onResetPassword(_ sender: Any) {
        if (txtPassword.text?.isEmpty)! {
            AlertUtil.showSimpleAlert(self, title: "Please enter new password.", message: nil, okButtonTitle: "OK")
            return
        }
        if (txtConfirm.text?.isEmpty)! {
            AlertUtil.showSimpleAlert(self, title: "Please enter password to confirm.", message: nil, okButtonTitle: "OK")
            return
        }
        
        let password = txtPassword.text
        let passwordToConfirm = txtConfirm.text
        
        if password != passwordToConfirm {
            AlertUtil.showSimpleAlert(self, title: "The passwords you entered don't match. Try again.", message: nil, okButtonTitle: "OK")
            return
        }
        
        self.btnReset.isEnabled = false
        
        UserService.Instance.updatePassword(token: self.token, new: password!, completion: {
            (success: Bool, code: Int?) in
            
            self.btnReset.isEnabled = true
            
            if success {
                AlertUtil.showOKAlert(self, message: "You have successfully reset your password.", okCompletionBlock: {
                    UserDefaultsUtil.DeleteForgotPasswordToken()
                    self.navigationController?.popToRootViewController(animated: false)
                })
            } else {
                AlertUtil.showSimpleAlert(self, title: "Failed to reset password. Please contact administrator.", message: nil, okButtonTitle: "OK")
            }
            
        })
    }
}
