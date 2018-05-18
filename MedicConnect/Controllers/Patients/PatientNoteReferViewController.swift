//
//  PatientNoteReferViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-12-22.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class PatientNoteReferViewController: BaseViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblPatientName: UILabel!
    @IBOutlet weak var lblPatientDOB: UILabel!
    @IBOutlet weak var lblPatientPHN: UILabel!
    
    @IBOutlet weak var viewReferringDoctor: UIView!
    @IBOutlet weak var lblDoctorName: UILabel!
    @IBOutlet weak var lblDoctorMSP: UILabel!
    @IBOutlet weak var constOfRefDoctorViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    
    @IBOutlet weak var btnSaveNote: UIButton!
    
    var activityIndicatorView = UIActivityIndicatorView()
    
    var noteInfo: [String: Any] = [:]
    var userIDs: [String: String] = ["refer": "", "view1": "", "view2" : "", "view3": ""]
    var isSaveNote: Bool = false
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if Yes is clicked on error popup
        if isSaveNote {
            self.saveNote()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialize views
    
    func initViews() {
        // Initialize
        
        let views: [UIView] = [view1, view2, view3]
        
        for view in views {
            let textField: UITextField = view.viewWithTag(10) as! UITextField
            let errorLabel: UILabel = view.viewWithTag(11) as! UILabel
            let nameLabel: UILabel = view.viewWithTag(12) as! UILabel
            
            textField.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
            textField.leftViewMode = .always
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            
            let ivCheck: UIImageView = UIImageView.init(frame: CGRect.init(x: 7, y: 16.5, width: 11, height: 11))
            ivCheck.image = UIImage.init(named: "icon_save_done_new")
            let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 25, height: 44))
            view.addSubview(ivCheck)
            
            textField.rightView = view
            textField.rightViewMode = .always
            textField.rightView?.isHidden = true
            
            // Hide error label
            errorLabel.isHidden = true
            
            nameLabel.text = ""
        }
        
        // Hide the other 2 fields
        self.view2.isHidden = true
        self.view3.isHidden = true
        
        if let _patient = DataManager.Instance.getPatient() {
            self.lblPatientName.text = _patient.name
            self.lblPatientDOB.text = "DOB \(_patient.getFormattedBirthDate().replacingOccurrences(of: ",", with: ""))"
            self.lblPatientPHN.text = "PHN# \(_patient.patientNumber)"
        }
        
        let _msp = DataManager.Instance.getReferringUserMSP()
        if _msp != "" {
            self.lblDoctorMSP.text = "MSP# \(_msp)"
            self.btnSaveNote.isUserInteractionEnabled = false
            
            UserService.Instance.getUserIdByMSP(MSP: _msp) { (success, MSP, userId, name) in
                DispatchQueue.main.async {
                    self.btnSaveNote.isUserInteractionEnabled = true
                    
                    if success == true && userId != nil && userId != "" {
                        self.lblDoctorName.text = name
                        self.userIDs["refer"] = userId
                    }
                }
                
//                let textField: UITextField = self.view1.viewWithTag(10) as! UITextField
//                let errorLabel: UILabel = self.view1.viewWithTag(11) as! UILabel
//                let nameLabel: UILabel = self.view1.viewWithTag(12) as! UILabel
//
//                DispatchQueue.main.async {
//                    self.btnSaveNote.isUserInteractionEnabled = true
//
//                    if success == true && userId != nil && userId != "" {
//                        self.lblDoctorName.text = name
//
//                        self.userIDs["view1"] = userId
//                        nameLabel.text = name!
//                        errorLabel.isHidden = true
//                        textField.text = _msp
//                        textField.textColor = UIColor.black
//                        textField.rightView?.isHidden = false
//                    }
//                }
            }
        } else {
            // Hide Referring Doctor View
            self.constOfRefDoctorViewHeight.constant = 0
        }
        
    }
    
    // MARK: Private Methods
    
    func presentErrorPopup(_ popupType: ErrorPopupType) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ErrorPopupViewController") as? ErrorPopupViewController {
            vc.popupType = popupType
            vc.fromPatientNote = true
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func presentSharePopup(_ postId: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ShareBroadcastViewController") as? ShareBroadcastViewController {
            vc.postId = postId
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
}

extension PatientNoteReferViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        return newLength <= Constants.MaxMSPLength
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // When the user performs a repeating action, such as entering text, invoke the `call` method
        textField.textColor = UIColor.black
        textField.rightView?.isHidden = true
        
        if textField.superview! == self.view1 {
            self.userIDs["view1"] = ""
        } else if textField.superview! == self.view2 {
            self.userIDs["view2"] = ""
        } else if textField.superview! == self.view3 {
            self.userIDs["view3"] = ""
        }
        
        let nameLabel: UILabel = textField.superview!.viewWithTag(12) as! UILabel
        nameLabel.text = ""
        
        debouncer.call()
        debouncer.callback = {
            // Send the debounced network request here
            if (textField.text!.count > 0) {
                // Check if MSP number exists
                self.btnSaveNote.isUserInteractionEnabled = false
                UserService.Instance.getUserIdByMSP(MSP: textField.text!) { (success, MSP, userId, name) in
                    let label: UILabel = textField.superview!.viewWithTag(11) as! UILabel
                    
                    DispatchQueue.main.async {
                        self.btnSaveNote.isUserInteractionEnabled = true
                        
                        if success == true && MSP == textField.text! {
                            if userId == nil || userId == "" {
                                label.isHidden = false
                                textField.textColor = UIColor.red
                            } else {
                                if textField.superview! == self.view1 {
                                    self.userIDs["view1"] = userId
                                } else if textField.superview! == self.view2 {
                                    self.userIDs["view2"] = userId
                                } else if textField.superview! == self.view3 {
                                    self.userIDs["view3"] = userId
                                }
                                
                                nameLabel.text = name!
                                label.isHidden = true
                                textField.textColor = UIColor.black
                            }
                        } else if success == false {
                            label.isHidden = false
                            textField.textColor = UIColor.red
                        }
                        
                        textField.rightView?.isHidden = !label.isHidden
                    }
                    
                }
            }
        }
    }
}

extension PatientNoteReferViewController {
    
    //MARK: IBActions
    
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
    
    func saveNote() {
        
        // Save Note
        self.startIndicating()
        self.btnSaveNote.isEnabled = false
        
        PostService.Instance.sendPost(noteInfo["title"] as! String,
                                      author: noteInfo["author"] as! String,
                                      description: noteInfo["description"] as! String,
                                      hashtags: noteInfo["hashtags"] as! [String],
                                      postType: noteInfo["postType"] as! String,
                                      diagnosticCode: noteInfo["diagnosticCode"] as! String,
                                      billingCode: noteInfo["billingCode"] as! String,
                                      audioData: noteInfo["audioData"] as! Data,
                                      image: nil,
                                      fileExtension: noteInfo["fileExtension"] as! String,
                                      mimeType: noteInfo["mimeType"] as! String,
                                      completion: { (success: Bool, postId: String?) in
                                        
                                        // As we just posted a new audio, it's a good thing to refresh user info.
                                        
                                        if self.constOfRefDoctorViewHeight.constant == 0 {
                                            // Go to share post screen
                                            DispatchQueue.main.async {
                                                self.stopIndicating()
                                                self.btnSaveNote.isEnabled = true
                                                self.presentSharePopup(postId!)
                                            }
                                        } else {
                                            // Automatic Transcription
                                            PostService.Instance.placeOrder(postId: postId!, completion: { (success: Bool) in
                                                
                                                DispatchQueue.main.async {
                                                    self.stopIndicating()
                                                    self.btnSaveNote.isEnabled = true
                                                    
                                                    if let _nav = self.navigationController as UINavigationController? {
                                                        _nav.dismiss(animated: false, completion: nil)
                                                    } else {
                                                        self.dismiss(animated: false, completion: nil)
                                                    }
                                                }
                                                
                                                if !success {
                                                    DispatchQueue.main.async {
                                                        AlertUtil.showSimpleAlert(self, title: "Transcription failed. Please try again.", message: nil, okButtonTitle: "OK")
                                                    }
                                                }
                                                
                                            })
                                        }
                                        
        })
        
    }
    
    @IBAction func onBack(sender: UIButton!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onAddDoctor(sender: UIButton!) {
        if (view2.isHidden) {
            let textField: UITextField = view1.viewWithTag(10) as! UITextField
            let label: UILabel = view1.viewWithTag(11) as! UILabel
            view2.isHidden = !(label.isHidden && !(textField.rightView?.isHidden)!)
        } else if (view3.isHidden && self.constOfRefDoctorViewHeight.constant == 0) {
            let textField1: UITextField = view1.viewWithTag(10) as! UITextField
            let label1: UILabel = view1.viewWithTag(11) as! UILabel
            let textField2: UITextField = view2.viewWithTag(10) as! UITextField
            let label2: UILabel = view2.viewWithTag(11) as! UILabel
            view3.isHidden = !(label1.isHidden && !(textField1.rightView?.isHidden)! && label2.isHidden && !(textField2.rightView?.isHidden)!)
        }
    }
    
    @IBAction func onSaveNote(sender: UIButton!) {
        // Save Note
        var doctorIds: [String] = []
        
        for (_, value) in self.userIDs {
            if value != "" {
                doctorIds.append(value)
            }
        }
        
        DataManager.Instance.setReferringUserIds(referringUserIds: doctorIds)
        
        if doctorIds.count == 0 {
            // Show Error Popup
            self.presentErrorPopup(.noMSP)
            return
        }
        
        self.saveNote()
        
    }
    
    @IBAction func onSkip(sender: UIButton!) {
        // Skip referring users
        if self.constOfRefDoctorViewHeight.constant == 0 {
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
        }
        
        self.saveNote()
    }
    
}
