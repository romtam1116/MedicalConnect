//
//  ErrorPopupViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-12-20.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

public enum ErrorPopupType {
    case none
    case noMSP
    case noPHN
    case noMSPAndPHN
    case exceedLimit
}

class ErrorPopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var ivAlertImage: UIImageView!
    @IBOutlet var lblAlertMark: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblQuestion: UILabel!
    
    @IBOutlet var btnNo: UIButton!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var viewYes: UIView!
    
    @IBOutlet var constOfViewHeight: NSLayoutConstraint!
    
    var popupType: ErrorPopupType = .none
    var isYes: Bool = false
    var fromPatientNote: Bool = false
    var fromConsult: Bool = false
    
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
    
    func initViews() {
        
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        if self.popupType == .exceedLimit {
            self.ivAlertImage.isHidden = false
            self.lblAlertMark.isHidden = true
        } else {
            self.ivAlertImage.isHidden = true
            self.lblAlertMark.isHidden = false
        }
        
        switch (self.popupType) {
        case .noMSP:
            self.constOfViewHeight.constant = 212.0
            self.lblDescription.text = "You didn't enter correct Doctor's MSP"
            self.lblQuestion.text = "Would you like to\ncontinue without associating this\nconsult with a referring doctor?"
            break
            
        case .noPHN:
            self.constOfViewHeight.constant = 244.0
            self.lblDescription.text = "Whoops, you need to associate\na patient with this consult."
            self.lblQuestion.text = "Please enter an existing patient’s PHN\nor create a new patient."
            self.btnNo.isHidden = true
            self.btnYes.setTitle("OK", for: .normal)
            break
            
        case .noMSPAndPHN:
            self.constOfViewHeight.constant = 244.0
            self.lblDescription.text = "You didn't enter correct Patient's PHN\nor Doctor's MSP"
            self.lblQuestion.text = "Would you like to\ncontinue without associating this\nconsult with a patient or\nreferring doctor?"
            break
            
        case .exceedLimit:
            self.constOfViewHeight.constant = 212.0
            self.lblDescription.text = "The length of your \(DataManager.Instance.getPostType() == Constants.PostTypeConsult ? Constants.PostTypeConsult.lowercased() : "patient \(Constants.PostTypeNote.lowercased())") has\nexceeded 2 minutes."
            self.lblQuestion.text = "Would you like to\ncontinue recording?"
            break
            
        default:
            break
        }
        
        // Buttons highlighted status
        self.btnNo.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        self.btnYes.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        
    }
    
    func close() {
        if let _nav = self.navigationController as UINavigationController? {
            if isYes == true {
                _nav.popToRootViewController(animated: false)
            } else {
                _nav.popViewController(animated: false)
            }
            
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func goBackToRecording(continueRecording: Bool) {
        let lenght = self.navigationController?.viewControllers.count
        if let recordingVC = self.navigationController?.viewControllers[lenght! - 2] as? RecordingBroadcastViewController {
            recordingVC.continueRecording = continueRecording
            self.navigationController?.popViewController(animated: false)
        }
    }
    
}

extension ErrorPopupViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        if self.popupType == .exceedLimit {
            self.goBackToRecording(continueRecording: false)
        } else {
            self.isYes = false
            self.close()
        }
    }
    
    @IBAction func onNo(sender: UIButton) {
        self.onClose(sender: nil)
    }
    
    @IBAction func onYes(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if fromPatientNote == true || fromConsult == true {
            
            let lenght = self.navigationController?.viewControllers.count
            if fromPatientNote {
                let patientNoteVC: PatientNoteReferViewController? = lenght! >= 2 ? self.navigationController?.viewControllers[lenght! - 2] as? PatientNoteReferViewController : nil
                patientNoteVC?.isSaveNote = true
            } else if fromConsult {
                let patientNoteVC: ConsultReferringViewController? = lenght! >= 2 ? self.navigationController?.viewControllers[lenght! - 2] as? ConsultReferringViewController : nil
                patientNoteVC?.isSaveConsult = self.popupType == .noPHN ? false : true
            }
            
            self.onClose(sender: nil)
            
        }  else if self.popupType == .exceedLimit {
            
            self.goBackToRecording(continueRecording: true)
            
        } else {
            
            if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
                
                DataManager.Instance.setFromPatientProfile(false)
                
                weak var weakSelf = self
                self.present(vc, animated: false, completion: {
                    weakSelf?.isYes = true
                    weakSelf?.close()
                })
                
            }
            
        }
    }
    
}
