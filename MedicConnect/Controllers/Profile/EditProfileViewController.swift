//
//  EditProfileViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/28/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

let updatedProfileNotification = NSNotification.Name(rawValue:"userUpdated")

class EditProfileViewController: BaseViewController {
    
    @IBOutlet var imgAvatar: RadAvatar!
    @IBOutlet var tfName: ACFloatingTextfield!
    @IBOutlet var tfTitle: ACFloatingTextfield!
    @IBOutlet var tfMSP: ACFloatingTextfield!
    @IBOutlet var tfLocation: ACFloatingTextfield!
    @IBOutlet var tfPhoneNumber: ACFloatingTextfield!
    @IBOutlet var tfEmail: ACFloatingTextfield!
    @IBOutlet var lblMSPError: UILabel!
    @IBOutlet var btnChangePicture: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    var activityIndicatorView = UIActivityIndicatorView()
    var alertWindow: UIWindow!
    
    let debouncer = Debouncer(interval: 1.0)
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Name
        self.tfName.placeholder = NSLocalizedString("Name", comment: "comment")
        
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
        
        // Email
        self.tfEmail.placeholder = NSLocalizedString("Email", comment: "comment")
        
        self.tfEmail.isEnabled = false
        
        if let _user = UserController.Instance.getUser() as User? {
            
            // Customize Avatar
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                         text: _user.getInitials(),
                                                                                         font: UIFont(name: "Avenir-Book", size: 40)!,
                                                                                         size: CGSize(width: 84, height: 84))
            }
            
            self.tfName.text = _user.fullName
            self.tfTitle.text = _user.title
            self.tfMSP.text = _user.msp
            self.tfLocation.text = _user.location
            self.tfPhoneNumber.text = _user.phoneNumber
            self.tfEmail.text = _user.email
            
        }
        
        // Change Picture Button
        self.btnChangePicture.layer.cornerRadius = 14
        self.btnChangePicture.clipsToBounds = true
        self.btnChangePicture.layer.borderColor = UIColor.init(red: 113/255.0, green: 127/255.0, blue: 134/255.0, alpha: 1.0).cgColor
        self.btnChangePicture.layer.borderWidth = 1
        
    }
    
    func uploadImage() {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            if let _image = self.imgAvatar.image as UIImage? {
                
                self.startIndicating()
                UserService.Instance.postUserImage(id: _user.id, image: _image, completion: {
                    (success: Bool) in
                    print("\(success) uploading image.")
                    
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        
                        let nc = NotificationCenter.default
                        nc.post(name: updatedProfileNotification, object: nil, userInfo: nil)
                        self.stopIndicating()
                        
                    })
                    
                })
                
            } else {
                print("No image found")
            }
            
        } else {
            print("No user found")
        }
        
    }
    
    // MARK: Activity Indicator
    
    func startIndicating(){
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicating() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.removeFromSuperview()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
}

extension EditProfileViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfName) {
            return newLength <= Constants.MaxFullNameLength
        } else if (textField == self.tfPhoneNumber) { /// phone number
            return newLength <= Constants.MaxPhoneNumberLength
        } else if (textField == self.tfMSP) { /// msp
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
                    if let _user = UserController.Instance.getUser() as User? {
                        if _user.msp == textField.text! {
                            self.lblMSPError.isHidden = true
                            self.btnSave.isUserInteractionEnabled = true
                            
                            return
                        }
                    }
                    
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

extension EditProfileViewController : UINavigationControllerDelegate {
    
    //MARK: UIImagePickerControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
}

extension EditProfileViewController : UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var isChanged = false
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imgAvatar.image = pickedImage
            isChanged = true
        }

        dismiss(animated: true) {
            if(isChanged){
                self.uploadImage()
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension EditProfileViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSaveChange(sender: AnyObject!) {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            var profileFilled = true
            
            if self.tfName.text != "" {
                _user.fullName = self.tfName.text!
            } else {
                profileFilled = false
            }
            
            if self.tfTitle.text != "" {
                _user.title = self.tfTitle.text!
            } else {
                profileFilled = false
            }
            
            if self.tfMSP.text != "" {
                if !self.lblMSPError.isHidden {
                    return
                }
                
                _user.msp = self.tfMSP.text!
            } else {
                profileFilled = false
            }
            
            if self.tfLocation.text != "" {
                _user.location = self.tfLocation.text!
            } else {
                profileFilled = false
            }
            
            if self.tfPhoneNumber.text != "" {
                _user.phoneNumber = self.tfPhoneNumber.text!
            } else {
                profileFilled = false
            }
            
            if !profileFilled {
                AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to fill out the form!", message: nil, okButtonTitle: "OK")
                return
            }
            
            self.startIndicating()
            UserService.Instance.editUser(user: _user, completion: {
                (success: Bool, message: String) in
                self.stopIndicating()
                
                if success {
                    self.onBack(sender: nil)
                } else {
                    if !message.isEmpty {
                        AlertUtil.showSimpleAlert(self, title: message, message: nil, okButtonTitle: "OK")
                    }
                }
                
            })
            
        } else {
            self.onBack(sender: nil)
        }
    
    }
    
    @IBAction func onChangePhoto(sender: AnyObject!) {
        
        self.alertWindow = UIWindow(frame: UIScreen.main.bounds)
        self.alertWindow.rootViewController = UIViewController()
        self.alertWindow.windowLevel = 10000001
        self.alertWindow.isHidden = false
        
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Choose from Albums
        let albumAction = UIAlertAction(title: NSLocalizedString("Choose from Album", comment: "comment"), style: .default, handler: {
            (act: UIAlertAction) in
            let sourceType = UIImagePickerControllerSourceType.photoLibrary
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                let picker = UIImagePickerController()
                picker.sourceType = sourceType
                picker.delegate = self
                picker.allowsEditing = true
                self.present(picker, animated: true, completion: nil)
            }
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(albumAction)
        
        // Take a Photo
        let photoAction = UIAlertAction(title: NSLocalizedString("Take a Photo", comment: "comment"), style: .destructive, handler: {
            (act: UIAlertAction) in
            let sourceType = UIImagePickerControllerSourceType.camera
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                let picker = UIImagePickerController()
                picker.sourceType = sourceType
                picker.delegate = self
                picker.allowsEditing = true
                self.present(picker, animated: true, completion: nil)
            }
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(photoAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "comment"), style: .default, handler: {
            (act: UIAlertAction) in
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(cancelAction)
        
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
    
}
