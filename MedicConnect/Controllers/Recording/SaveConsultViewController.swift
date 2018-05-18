//
//  SaveConsultViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-01-17.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import UIKit
import TLTagsControl
import MobileCoreServices

class SaveConsultViewController: BaseViewController {
    
    var activityIndicatorView = UIActivityIndicatorView()
    var fileURL: URL?
    
    let billingCodes = ["1470", "1472"]
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblPostTitle: UILabel!
    @IBOutlet var lblPostDescription: UILabel!
    
    @IBOutlet var tfBroadcastName: UITextField!
    @IBOutlet var tvDescription: RadContentHeightTextView!
    @IBOutlet var tfDiagnosticCode: UITextField!
    @IBOutlet var tfBillingCode: UITextField!
    @IBOutlet var hashTagCtrl: TLTagsControl!
    
    @IBOutlet var btnSave: UIButton!
    @IBOutlet var alertWindow: UIWindow!
    
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
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    //MARK: Initialize views
    
    func initViews() {
        
        // Title
        self.lblTitle.text = "Save \(DataManager.Instance.getPostType() == Constants.PostTypeConsult ? Constants.PostTypeConsult : "Patient \(Constants.PostTypeNote)")"
        self.lblPostDescription.text = "\(DataManager.Instance.getPostType() == Constants.PostTypeConsult ? Constants.PostTypeConsult : "Patient") Brief"
        self.btnSave.setTitle("SAVE \(DataManager.Instance.getPostType().uppercased())", for: .normal)
        
        // Description
        self.tvDescription.minHeight = 30
        self.tvDescription.maxHeight = 150
        
        // Billing Code
        let billingCodePicker = UIPickerView()
        billingCodePicker.delegate = self
        billingCodePicker.dataSource = self
        self.tfBillingCode.inputView = billingCodePicker
        
        // Hashtags
        self.hashTagCtrl.tagsBackgroundColor = UIColor(red: 205/255, green: 212/255, blue: 215/255, alpha: 1.0)
        self.hashTagCtrl.tagsTextColor = UIColor.white
        self.hashTagCtrl.tagsDeleteButtonColor = UIColor.white
        self.hashTagCtrl.reloadTagSubviews()
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}

extension SaveConsultViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfBroadcastName) {
            return newLength <= Constants.MaxFullNameLength
        } else if (textField == self.tfDiagnosticCode) {
            return newLength <= Constants.MaxDiagnosticCodeLength
        } else {
            return true
        }
        
    }
}

extension SaveConsultViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let description = textView.text else { return true }
        
        let newLength = description.count + text.count - range.length
        return newLength <= Constants.MaxDescriptionLength
    }
}

extension SaveConsultViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: UIPickerView Delegation
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return billingCodes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return billingCodes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.tfBillingCode.text = billingCodes[row]
    }

}

extension SaveConsultViewController {
    
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
    
    @IBAction func onClose(sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = true
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSave(sender: UIButton) {
        
        let postType = DataManager.Instance.getPostType()
//        let title = self.tfBroadcastName.text!
//        guard  title.count != 0 else {
//            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your \(postType.lowercased()) a name!", message: nil, okButtonTitle: "OK")
//            return
//        }
        
//        guard  self.tfDiagnosticCode.text!.count != 0 else {
//            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your \(postType.lowercased()) a diagnostic code!", message: nil, okButtonTitle: "OK")
//            return
//        }
//        
//        guard  self.tfBillingCode.text!.count != 0 else {
//            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your \(postType.lowercased()) a billing code!", message: nil, okButtonTitle: "OK")
//            return
//        }
        
        var author = ""
        if let _user = UserController.Instance.getUser() as User? {
            author = _user.fullName
        }
        
        let fromPatientProfile = DataManager.Instance.getFromPatientProfile()
        
        var audioFilename: URL
        if (self.fileURL != nil) {
            audioFilename = self.fileURL!
        } else {
            audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        }
        
        let fileExtension = audioFilename.pathExtension
        let fileMimeType = fileExtension.mimeTypeForPathExtension()
        
        do {
            let audioData = try Data(contentsOf: audioFilename)
            let postInfo = ["title" : "",
                            "author" : author,
                            "description" : self.tvDescription.text!,
                            "hashtags" : hashTagCtrl.tags as! [String],
                            "postType" : postType,
                            "diagnosticCode" : self.tfDiagnosticCode.text!,
                            "billingCode" : self.tfBillingCode.text!,
                            "audioData" : audioData,
                            "fileExtension": fileExtension,
                            "mimeType": fileMimeType] as [String : Any]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if fromPatientProfile || (DataManager.Instance.getPatient() != nil && DataManager.Instance.getReferringUserMSP() != "") {
                // From Patient Profile
                if let vc = storyboard.instantiateViewController(withIdentifier: "PatientNoteReferViewController") as? PatientNoteReferViewController {
                    vc.noteInfo = postInfo
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            } else {
                // From Profile Consult
                if let vc = storyboard.instantiateViewController(withIdentifier: "ConsultReferringViewController") as? ConsultReferringViewController {
                    vc.consultInfo = postInfo
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
            
        } catch let error {
            self.btnSave.isEnabled = true
            print(error.localizedDescription)
        }
        
    }
    
}
