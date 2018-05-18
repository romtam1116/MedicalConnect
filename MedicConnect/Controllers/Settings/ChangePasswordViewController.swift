//
//  ChangePasswordViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/25/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class ChangePasswordViewController: BaseViewController {
    
    let ChangePasswordListCellID = "ChangePasswordListCell"
    
    @IBOutlet var tvChangePassword: UITableView!
    @IBOutlet var btnSave: UIButton!
    
    fileprivate var newPassword: String = ""
    fileprivate var currentPassword: String = ""
    fileprivate var confirmPassword: String = ""
    
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
    
    //MARK: Private methods
    
    func initViews() {
        
        // Initialize Table Views
        self.tvChangePassword.register(UINib(nibName: ChangePasswordListCellID, bundle: nil), forCellReuseIdentifier: ChangePasswordListCellID)
        self.tvChangePassword.tableFooterView = UIView()
        self.tvChangePassword.allowsSelection = false
        
    }
    
}

extension ChangePasswordViewController : UITableViewDataSource, UITableViewDelegate {

    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tvChangePassword {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tvChangePassword {
            
            switch (section) {
            case 0:
                return 1
            case 1:
                return 2
                
            default:
                break
            }
            
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvChangePassword {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ChangePasswordListCellID) as! ChangePasswordListCell
            
            if indexPath.section == 0 {
                
                cell.setCellWithTitle(title: NSLocalizedString("Current Password", comment: "comment"))
                cell.txField.tag = 1
                cell.txField.delegate = self
                
            } else if indexPath.section == 1 {
                
                if indexPath.row == 0 {
                    
                    cell.setCellWithTitle(title: NSLocalizedString("New Password", comment: "comment"))
                    cell.txField.tag = 2
                    cell.txField.delegate = self
                    
                } else if indexPath.row == 1 {
                    
                    cell.setCellWithTitle(title: NSLocalizedString("Confirm Password", comment: "comment"))
                    cell.txField.tag = 3
                    cell.txField.delegate = self
                }
                
            }
            
            return cell
        }
        
        return UITableViewCell()
        
    }
    
    //MARK: UITableView Delegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView == self.tvChangePassword {
            
            if section == 0 {
                
                return nil
                
            } else if section == 1 {
            
                return NSLocalizedString("Update", comment: "comment")
                
            }
            
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tvChangePassword {
            return 70.0
        }
        
        return 0.0
        
    }
}

extension ChangePasswordViewController : UITextFieldDelegate {

    //MARK: UITextField delegate methods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        switch textField.tag {
        case 1:
            self.currentPassword = textField.text as String? ?? ""
            break
            
        case 2:
            self.newPassword = textField.text as String? ?? ""
            break
        
        case 3:
            self.confirmPassword = textField.text as String? ?? ""
            break
            
        default:
            print("UITextField not mapped.")
            break
        }
        
    }
    
}

extension ChangePasswordViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onSave(_ sender: Any) {
        
        self.view.endEditing(true)
        
        // Check if all required fields are filled
        if self.currentPassword.isEmpty || self.newPassword.isEmpty || self.confirmPassword.isEmpty {
            AlertUtil.showSimpleAlert(self, title: "Please fill in all fields", message: nil, okButtonTitle: "OK")
            return
        }
        
        // Check if passwords match
        if self.newPassword != self.confirmPassword {
            AlertUtil.showSimpleAlert(self, title: "The passwords don't match", message: nil, okButtonTitle: "OK")
            return
        }
        
        self.btnSave.isEnabled = false
        
        // Send change password request
        UserService.Instance.changePassword(currentPassword: self.currentPassword, newPassword: self.newPassword, completion: {
            (success: Bool, message: String) in
            
            self.btnSave.isEnabled = true
            
            if success {
                AlertUtil.showSimpleAlert(self, title: "Your password has been successfully changed", message: nil, okButtonTitle: "OK")
            } else {
                if !message.isEmpty {
                    AlertUtil.showSimpleAlert(self, title: message, message: nil, okButtonTitle: "OK")
                }
            }
            
        })
        
    }
    
}
