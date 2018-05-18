//
//  ConsultReferringViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-12-14.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import SwiftValidators

class ConsultReferringViewController: BaseViewController {

    @IBOutlet weak var tfPatientNumber: UITextField!
    @IBOutlet weak var tfDoctorMSPNumber: UITextField!
    
    @IBOutlet weak var lblPHNError: UILabel!
    @IBOutlet weak var lblPatientName: UILabel!
    @IBOutlet weak var lblMSPError: UILabel!
    @IBOutlet weak var lblDoctorName: UILabel!
    
    @IBOutlet weak var btnSave: UIButton!
    
    var activityIndicatorView = UIActivityIndicatorView()
    
    var btnCameraScan: UIButton?
    var viewCheckmark: UIView?
    
    var consultInfo: [String: Any] = [:]
    var patientID: String = ""
    var referUserID: String = ""
    var isSaveConsult: Bool = false
    
    var scanResults: [RTRTextLine]? = nil
    
    let debouncer = Debouncer(interval: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
        self.showScanResult()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if Yes is clicked on error popup
        if isSaveConsult {
            self.saveConsult()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialize views
    
    func initViews() {
        self.tfPatientNumber.delegate = self
        self.tfDoctorMSPNumber.delegate = self
        
        self.tfPatientNumber.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        self.tfPatientNumber.leftViewMode = .always
        self.tfPatientNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.btnCameraScan = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 44, height: 44))
        self.btnCameraScan?.setImage(UIImage(named: "icon_camera_scan"), for: .normal)
        self.btnCameraScan?.addTarget(self, action: #selector(onScanPatient(sender:)), for: .touchUpInside)
        
        let imageView: UIImageView = UIImageView.init(frame: CGRect.init(x: 7, y: 16.5, width: 11, height: 11))
        imageView.image = UIImage.init(named: "icon_save_done_new")
        self.viewCheckmark = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 25, height: 44))
        self.viewCheckmark?.addSubview(imageView)
        
        self.tfPatientNumber.rightView = self.btnCameraScan
        self.tfPatientNumber.rightViewMode = .always
        
        self.tfDoctorMSPNumber.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        self.tfDoctorMSPNumber.leftViewMode = .always
        self.tfDoctorMSPNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        let ivCheck: UIImageView = UIImageView.init(frame: CGRect.init(x: 7, y: 16.5, width: 11, height: 11))
        ivCheck.image = UIImage.init(named: "icon_save_done_new")
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 25, height: 44))
        view.addSubview(ivCheck)
        
        self.tfDoctorMSPNumber.rightView = view
        self.tfDoctorMSPNumber.rightViewMode = .always
        
        // Hide error labels
        self.lblPHNError.isHidden = true
        self.lblMSPError.isHidden = true
        
        self.lblPatientName.text = ""
        self.lblDoctorName.text = ""
        
        // Hide checkmark
        self.tfDoctorMSPNumber.rightView?.isHidden = true
        
        if let _patient = DataManager.Instance.getPatient() {
            self.patientID = _patient.id
            self.lblPatientName.text = _patient.name
            self.lblPHNError.isHidden = true
            self.tfPatientNumber.text = _patient.patientNumber
            self.tfPatientNumber.rightView = self.viewCheckmark
            self.tfPatientNumber.textColor = UIColor.black
        }
        
        let _msp = DataManager.Instance.getReferringUserMSP()
        if _msp != "" {
            self.tfDoctorMSPNumber.text = _msp
            self.btnSave.isUserInteractionEnabled = false
            
            UserService.Instance.getUserIdByMSP(MSP: self.tfDoctorMSPNumber.text!) { (success, MSP, userId, name) in
                DispatchQueue.main.async {
                    self.btnSave.isUserInteractionEnabled = true
                    
                    if success == true && MSP == self.tfDoctorMSPNumber.text! {
                        if userId == nil || userId == "" {
                            self.lblMSPError.isHidden = false
                            self.tfDoctorMSPNumber.textColor = UIColor.red
                        } else {
                            self.referUserID = userId!
                            self.lblDoctorName.text = name!
                            self.lblMSPError.isHidden = true
                            self.tfDoctorMSPNumber.textColor = UIColor.black
                        }
                    } else if success == false {
                        self.lblMSPError.isHidden = false
                        self.tfDoctorMSPNumber.textColor = UIColor.red
                    }
                    
                    self.tfDoctorMSPNumber.rightView?.isHidden = !self.lblMSPError.isHidden
                }
            }
        }
        
    }
    
    func showScanResult() {
        // Get patient PHN from scan results
        if let _textLines = self.scanResults {
            var phn: String = ""
            for textLine in _textLines {
                let text = textLine.text as String
                
                if text.count >= 13 && (text.contains("HCN") || text.contains("PHN")) {
                    // Possibly Patient Number
                    phn = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    break
                    
                } else if text.count == 10 && Validator.isNumeric().apply(text) {
                    // Possibly Patient Number
                    phn = text
                    break
                }
            }
            
            if phn != "" {
                self.tfPatientNumber.text = phn
                
                // Check if patient exists
                self.btnSave.isUserInteractionEnabled = false
                PatientService.Instance.getPatientIdByPHN(PHN: self.tfPatientNumber.text!) { (success, PHN, patientId, patientName) in
                    self.btnSave.isUserInteractionEnabled = true
                    
                    if success == true && PHN == self.tfPatientNumber.text! {
                        if patientId == nil || patientId == "" {
                            self.lblPHNError.isHidden = false
                            self.tfPatientNumber.textColor = UIColor.red
                        } else {
                            self.patientID = patientId!
                            self.lblPatientName.text = patientName!
                            self.lblPHNError.isHidden = true
                            self.tfPatientNumber.textColor = UIColor.black
                        }
                    } else if success == false {
                        self.lblPHNError.isHidden = false
                        self.tfPatientNumber.textColor = UIColor.red
                    }
                    
                    if self.lblPHNError.isHidden {
                        self.tfPatientNumber.rightView = self.viewCheckmark
                    }
                }
            }
        }
    }
    
    // MARK: Private Methods
    
    func presentCreatePatient(_ patientNumber: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        AlertUtil.showConfirmAlert(self, title: NSLocalizedString("Would you like to scan label?", comment: "comment"), message: nil, okButtonTitle: NSLocalizedString("YES", comment: "comment"), cancelButtonTitle: NSLocalizedString("NO", comment: "comment"), okCompletionBlock: {
            // OK completion block
            DispatchQueue.main.async {
                self.onScanPatient(sender: nil)
            }
        }, cancelCompletionBlock: {
            // Cancel completion block
            DispatchQueue.main.async {
                if let vc = storyboard.instantiateViewController(withIdentifier: "CreatePatientViewController") as? CreatePatientViewController {
                    vc.fromRecord = true
                    vc.patientNumber = patientNumber
                    
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
        })
    }
    
    func presentErrorPopup(_ popupType: ErrorPopupType) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ErrorPopupViewController") as? ErrorPopupViewController {
            vc.popupType = popupType
            vc.fromConsult = true
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func presentRecordScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setFromPatientProfile(false)
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.onBack(sender: nil)
            })
            
        }
    }
    
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
    
    func saveConsult() {
        // Save consult
        self.startIndicating()
        self.btnSave.isEnabled = false
        
        DataManager.Instance.setReferringUserMSP(referringUserMSP: "")
        
        PostService.Instance.sendPost(consultInfo["title"] as! String,
                                      author: consultInfo["author"] as! String,
                                      description: consultInfo["description"] as! String,
                                      hashtags: consultInfo["hashtags"] as! [String],
                                      postType: consultInfo["postType"] as! String,
                                      diagnosticCode: consultInfo["diagnosticCode"] as! String,
                                      billingCode: consultInfo["billingCode"] as! String,
                                      audioData: consultInfo["audioData"] as! Data,
                                      image: nil,
                                      fileExtension: consultInfo["fileExtension"] as! String,
                                      mimeType: consultInfo["mimeType"] as! String,
                                      completion: { (success: Bool, postId: String?) in
            
            if success {
                DispatchQueue.main.async {
                    self.stopIndicating()
                    self.btnSave.isEnabled = true
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "ShareBroadcastViewController") as? ShareBroadcastViewController {
                        vc.postId = postId
                        self.navigationController?.pushViewController(vc, animated: false)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.stopIndicating()
                    self.btnSave.isEnabled = true
                }
            }
        })
    }

}

extension ConsultReferringViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfPatientNumber) {
            return newLength <= Constants.MaxPHNLength
        } else if (textField == self.tfDoctorMSPNumber) {
            return newLength <= Constants.MaxMSPLength
        }
        
        return true
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // When the user performs a repeating action, such as entering text, invoke the `call` method
        textField.textColor = UIColor.black
        
        if (textField == self.tfPatientNumber) {
            self.lblPatientName.text = ""
            textField.rightView = self.btnCameraScan
        } else {
            self.lblDoctorName.text = ""
            textField.rightView?.isHidden = true
        }
        
        debouncer.call()
        debouncer.callback = {
            // Send the debounced network request here
            if (textField.text!.count > 0) {
                if (textField == self.tfPatientNumber) {
                    // Check if patient exists
                    self.btnSave.isUserInteractionEnabled = false
                    PatientService.Instance.getPatientIdByPHN(PHN: self.tfPatientNumber.text!) { (success, PHN, patientId, patientName) in
                        
                        DispatchQueue.main.async {
                            self.btnSave.isUserInteractionEnabled = true
                            
                            if success == true && PHN == self.tfPatientNumber.text! {
                                if patientId == nil || patientId == "" {
                                    self.lblPHNError.isHidden = false
                                    self.tfPatientNumber.textColor = UIColor.red
                                } else {
                                    self.patientID = patientId!
                                    self.lblPatientName.text = patientName!
                                    self.lblPHNError.isHidden = true
                                    self.tfPatientNumber.textColor = UIColor.black
                                }
                            } else if success == false {
                                self.lblPHNError.isHidden = false
                                self.tfPatientNumber.textColor = UIColor.red
                            }
                            
                            if self.lblPHNError.isHidden {
                                self.tfPatientNumber.rightView = self.viewCheckmark
                            }
                        }
                        
                    }
                } else if (textField == self.tfDoctorMSPNumber) {
                    // Check if MSP number exists
                    self.btnSave.isUserInteractionEnabled = false
                    UserService.Instance.getUserIdByMSP(MSP: self.tfDoctorMSPNumber.text!) { (success, MSP, userId, name) in
                        DispatchQueue.main.async {
                            self.btnSave.isUserInteractionEnabled = true
                            
                            if success == true && MSP == self.tfDoctorMSPNumber.text! {
                                if userId == nil || userId == "" {
                                    self.lblMSPError.isHidden = false
                                    self.tfDoctorMSPNumber.textColor = UIColor.red
                                } else {
                                    self.referUserID = userId!
                                    self.lblDoctorName.text = name!
                                    self.lblMSPError.isHidden = true
                                    self.tfDoctorMSPNumber.textColor = UIColor.black
                                }
                            } else if success == false {
                                self.lblMSPError.isHidden = false
                                self.tfDoctorMSPNumber.textColor = UIColor.red
                            }
                            
                            self.tfDoctorMSPNumber.rightView?.isHidden = !self.lblMSPError.isHidden
                        }
                    }
                }
            }
        }
    }
}

extension ConsultReferringViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: UIButton!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onScanPatient(sender: UIButton!) {
        self.view.endEditing(true)
        self.scanResults = nil
        
        // Show Scan screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if  let vc = storyboard.instantiateViewController(withIdentifier: "PatientScanViewController") as? PatientScanViewController {
            vc.fromConsult = true
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    @IBAction func onCreatePatient(sender: UIButton!) {
        self.presentCreatePatient("")
    }
    
    @IBAction func onSave(sender: UIButton!) {
        // Save consults and notes
        var errorType: ErrorPopupType = .none
        
        if (self.tfPatientNumber.text!.count == 0 || !self.lblPHNError.isHidden) {
            errorType = .noPHN
        } else if (self.tfDoctorMSPNumber.text!.count == 0 || !self.lblMSPError.isHidden) {
            errorType = .noMSP
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: self.patientID)
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
        }
        
        if (errorType != .none) {
            // Show Error Popup
            self.presentErrorPopup(errorType)
            return
        }
        
        DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
        DataManager.Instance.setPatientId(patientId: patientID)
        DataManager.Instance.setPatient(patient: nil)
        DataManager.Instance.setReferringUserIds(referringUserIds: [referUserID])
        
        // Save consult
        self.saveConsult()
        
    }
    
    @IBAction func onRecordConsult(sender: UIButton!) {
        // Go to Record screen
        var errorType: ErrorPopupType = .none
        if (self.tfPatientNumber.text!.count == 0 || !self.lblPHNError.isHidden) && (self.tfDoctorMSPNumber.text!.count == 0 || !self.lblMSPError.isHidden) {
            errorType = .noMSPAndPHN
            DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
            
        } else if (self.tfPatientNumber.text!.count == 0 || !self.lblPHNError.isHidden) {
            errorType = .noPHN
            DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setReferringUserIds(referringUserIds: [self.referUserID])
            
        } else if (self.tfDoctorMSPNumber.text!.count == 0 || !self.lblMSPError.isHidden) {
            errorType = .noMSP
            DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
            DataManager.Instance.setPatientId(patientId: self.patientID)
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
            
        }
        
        if (errorType != .none) {
            // Show Error Popup
            self.presentErrorPopup(errorType)
            return
        }
        
        DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
        DataManager.Instance.setPatientId(patientId: patientID)
        DataManager.Instance.setPatient(patient: nil)
        DataManager.Instance.setReferringUserIds(referringUserIds: [referUserID])
        
        // Show record screen
        self.presentRecordScreen()
        
    }
    
    @IBAction func onSkip(sender: UIButton!) {
        // Skip
        DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
        DataManager.Instance.setPatientId(patientId: "")
        DataManager.Instance.setPatient(patient: nil)
        DataManager.Instance.setReferringUserIds(referringUserIds: [])
        DataManager.Instance.setReferringUserMSP(referringUserMSP: "")
        
        // Show record screen
        self.presentRecordScreen()
    }
    
}
