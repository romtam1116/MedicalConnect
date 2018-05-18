//
//  EndCallPopupViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-04-03.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import UIKit

class EndCallPopupViewController: UIViewController {

    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var ivAlertImage: UIImageView!
    @IBOutlet var lblAlertMark: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblQuestion: UILabel!
    
    @IBOutlet var btnNo: UIButton!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var viewYes: UIView!
    
    var isYes: Bool = false
    var doctorId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    func initViews() {
        
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        self.ivAlertImage.isHidden = true
        self.lblAlertMark.isHidden = false
        
        // Buttons highlighted status
        self.btnNo.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        self.btnYes.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        
    }
    
    func close() {
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popToRootViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}

extension EndCallPopupViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        self.isYes = false
        self.close()
    }
    
    @IBAction func onNo(sender: UIButton) {
        self.onClose(sender: nil)
    }
    
    @IBAction func onYes(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
         
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setReferringUserIds(referringUserIds: [self.doctorId])
            DataManager.Instance.setFromPatientProfile(false)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let topNav = appDelegate.window?.rootViewController as! UINavigationController
            
            if let _msp = appDelegate.callHeaders["msp"] as! String? {
                DataManager.Instance.setReferringUserMSP(referringUserMSP: _msp)
            } else {
                DataManager.Instance.setReferringUserMSP(referringUserMSP: "")
            }
            
            if let _patientId = appDelegate.callHeaders["patientId"] as! String? {
                DataManager.Instance.setPatientId(patientId: _patientId)
            } else {
                DataManager.Instance.setPatientId(patientId: "")
            }
            
            if let tabBarController = topNav.viewControllers[1] as? UITabBarController {
                // Select Profile
                tabBarController.selectedIndex = 1
                
                self.dismiss(animated: false) {
                    if let navVC = tabBarController.viewControllers?[1] as? UINavigationController {
                        navVC.present(vc, animated: false, completion: nil)
                    }
                }
            } else {
                self.close()
            }
            
        }
    }

}
