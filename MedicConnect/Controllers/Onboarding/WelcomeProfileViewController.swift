//
//  WelcomeProfileViewController.swift
//  MedicalConsult
//
//  Created by Roman on 2/23/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class WelcomeProfileViewController: BaseViewController, UINavigationControllerDelegate {
    
    @IBOutlet var btnAvatarImage: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    @IBOutlet var tfTitle: ACFloatingTextfield!
    @IBOutlet var tfMSP: ACFloatingTextfield!
    @IBOutlet var tfLocation: ACFloatingTextfield!
    @IBOutlet var tfPhoneNumber: ACFloatingTextfield!
    @IBOutlet var lblMSPError: UILabel!
    
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var avatarImageView: UIImageView!
    
    @IBOutlet weak var lblTermsPrivacy: UILabel!
    @IBOutlet weak var btnTerms: UIButton!
    @IBOutlet weak var btnPrivacy: UIButton!
    
    var avatarImage: UIImage?
    var user: User? = nil
    
    let debouncer = Debouncer(interval: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Avatar Image View
        self.avatarImageView.layer.borderColor  = UIColor.white.cgColor
        
        // Title
        self.tfTitle.placeholder = NSLocalizedString("Title", comment: "comment")
        
        // MSP
        self.tfMSP.placeholder = NSLocalizedString("MSP #", comment: "comment")
        self.tfMSP.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.lblMSPError.isHidden = true
        
        // Location
        self.tfLocation.placeholder = NSLocalizedString("Site", comment: "comment")
        
        // Phone Number
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone #", comment: "comment")
        self.tfPhoneNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Terms of Use and Privacy Policy
        let string = self.lblTermsPrivacy.text!
        let myMutableString = NSMutableAttributedString(string: string,
                                                        attributes: [NSAttributedStringKey.font : UIFont(name: "Avenir-Book", size: 14.0)!])
        //Add more attributes here
        if let range = string.range(of: "Terms of Use") {
            let nsRange = string.nsRange(from: range)
            myMutableString.addAttribute(NSAttributedStringKey.font,
                                         value: UIFont(name: "Avenir-Black", size: 14.0)!,
                                         range: nsRange)
        }
        
        if let rangeP = string.range(of: "Privacy Policy") {
            let nsRange = string.nsRange(from: rangeP)
            myMutableString.addAttribute(NSAttributedStringKey.font,
                                         value: UIFont(name: "Avenir-Black", size: 14.0)!,
                                         range: nsRange)
        }
        
        //Apply to the label
        self.lblTermsPrivacy.attributedText = myMutableString
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    func openImagePicker(isGalleryMode: Bool) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = isGalleryMode ? .photoLibrary : .camera
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
}

extension WelcomeProfileViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfMSP) {
            return newLength <= Constants.MaxMSPLength
        }
        
        return true
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == self.tfPhoneNumber {
            // Format phone number
            textField.text = StringUtil.formatPhoneNumber(numberString: textField.text!)
            
        } else {
            // When the user performs a repeating action, such as entering text, invoke the `call` method
            debouncer.call()
            debouncer.callback = {
                // Send the debounced network request here
                if (textField == self.tfMSP && textField.text!.count > 0) {
                    // Check if patient exists
                    self.btnSave.isUserInteractionEnabled = false
                    
                    UserService.Instance.getUserIdByMSP(MSP: self.tfMSP.text!) { (success, MSP, userId, name) in
                        self.btnSave.isUserInteractionEnabled = true
                        
                        if success == true && MSP == self.tfMSP.text! {
                            if userId == nil || userId == "" {
                                self.lblMSPError.isHidden = true
                            } else {
                                self.lblMSPError.isHidden = false
                            }
                        } else if success == false {
                            self.lblMSPError.isHidden = true
                        }
                    }
                }
            }
        }
    }
}

extension WelcomeProfileViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func onTermsTapped(sender: AnyObject!) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
            vc.strTitle = "Terms of Use"
            present(vc, animated: false, completion: nil)
        }
    }
    
    @IBAction func onPrivacyTapped(sender: AnyObject!) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
            vc.strTitle = "Privacy Policy"
            present(vc, animated: false, completion: nil)
        }
    }
    
    @IBAction func tapPicture(_ sender: Any) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let galleryAction = UIAlertAction(title: NSLocalizedString("Choose from Album", comment: "comment"), style: .default) {
            action in
            self.openImagePicker(isGalleryMode: true)
        }
        alertController.addAction(galleryAction)
        
        let camAction = UIAlertAction(title: NSLocalizedString("Take a Photo", comment: "comment"), style: .destructive) {
            action in
            self.openImagePicker(isGalleryMode: false)
        }
        alertController.addAction(camAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "comment"), style: .cancel) {
            action in
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true) {}
        
    }
    
    @IBAction func tapSave(_ sender: Any) {
        
        guard self.user != nil else {
            print("No user found")
            return
        }
        
        guard self.tfTitle.text != "" else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to fill in your title!", message: nil, okButtonTitle: "OK")
            return
        }
        
        if self.tfMSP.text != "" {
            if !self.lblMSPError.isHidden {
                return
            }
        } else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to fill in your MSP number!", message: nil, okButtonTitle: "OK")
            return
        }
        
        guard self.tfLocation.text != "" else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to fill in your site!", message: nil, okButtonTitle: "OK")
            return
        }
        
        guard self.tfPhoneNumber.text != "" else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to fill in your phone number!", message: nil, okButtonTitle: "OK")
            return
        }
        
        self.btnSave.isEnabled = false
        
        UserService.Instance.signup(self.user!, completion: {
            (success: Bool, message: String) in
            
            if success {
                // Set FirstLoad to 0 to show tutorials for new users
                UserDefaultsUtil.SaveFirstLoad(firstLoad: 0)
                
                if let _user = UserController.Instance.getUser() as User? {
                    
                    _user.title = self.tfTitle.text!
                    _user.msp = self.tfMSP.text!
                    _user.location = self.tfLocation.text!
                    _user.phoneNumber = self.tfPhoneNumber.text!
                    
                    UserService.Instance.editUser(user: _user, completion: {
                        (success: Bool, message: String) in
                        if success {
                            if let _image = self.avatarImageView.image {
                                
                                UserService.Instance.postUserImage(id: _user.id, image: _image, completion: {
                                    (success: Bool) in
                                    print("\(success) uploading image.")
                                    
                                    if success {
                                        UserService.Instance.getMe(completion: {
                                            (user: User?) in
                                            
                                            DispatchQueue.main.async {
                                                self.performSegue(withIdentifier: Constants.SegueMedicConnectWelcomeLast, sender: nil)
                                            }
                                            
                                            print("\(success) refreshing user info.")
                                            
                                        })
                                    } else {
                                        self.btnSave.isEnabled = true
                                        AlertUtil.showSimpleAlert(self, title: "Uplading your profile image failed. Try again.", message: nil, okButtonTitle: "OK")
                                    }
                                })
                                
                            } else {
                                UserService.Instance.getMe(completion: {
                                    (user: User?) in
                                    
                                    DispatchQueue.main.async {
                                        self.performSegue(withIdentifier: Constants.SegueMedicConnectWelcomeLast, sender: nil)
                                    }
                                    
                                    print("\(success) refreshing user info.")
                                    
                                })
                            }
                            
                        } else {
                            self.btnSave.isEnabled = true
                            
                            if !message.isEmpty {
                                AlertUtil.showSimpleAlert(self, title: message, message: nil, okButtonTitle: "OK")
                            }
                        }
                    })
                    
                }
                
            } else {
                self.btnSave.isEnabled = true
                if !message.isEmpty {
                    AlertUtil.showSimpleAlert(self, title: message, message: nil, okButtonTitle: "OK")
                }
                
            }
            
        })
        
    }
    
}

extension WelcomeProfileViewController : UIImagePickerControllerDelegate{

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let _image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.btnAvatarImage.setImage(UIImage.init(), for: .normal)
            self.avatarImageView.image = _image
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension StringProtocol where Index == String.Index {
    func nsRange(from range: Range<Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}
