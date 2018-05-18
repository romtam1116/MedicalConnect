//
//  PreRecordingBroadcastViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/3/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation

class PreRecordingBroadcastViewController: BaseViewController {
    
    var fileURL: URL?
    
    @IBOutlet weak var patientInfoView: UIStackView!
    @IBOutlet weak var lblPatientName: UILabel!
    @IBOutlet weak var lblPatientDOB: UILabel!
    @IBOutlet weak var lblPatientPHN: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _patient = DataManager.Instance.getPatient() {
            self.lblPatientName.text = _patient.name
            self.lblPatientDOB.text = _patient.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
            self.lblPatientPHN.text = _patient.patientNumber
        } else if DataManager.Instance.getPatientId() != "" {
            // Get patient with id
            PatientService.Instance.getPatientById(patientId: DataManager.Instance.getPatientId(), completion: { (success, patient) in
                if success == true && patient != nil {
                    DataManager.Instance.setPatient(patient: patient)
                    
                    DispatchQueue.main.async {
                        self.lblPatientName.text = patient?.name
                        self.lblPatientDOB.text = patient?.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
                        self.lblPatientPHN.text = patient?.patientNumber
                    }
                }
            })
        } else {
            self.patientInfoView.isHidden = true
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = false
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
    
}

extension PreRecordingBroadcastViewController {
    //MARK: IBActions
    
    func processMicrophoneSettings() {
        let alertController = UIAlertController(title: "Setting", message: "You've already disabled microphone.\nGo to settings and enable microphone please.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            NotificationUtil.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        self.present(alertController, animated: false, completion: nil)
    }
    
    @IBAction func onRecordBroadcast(sender: AnyObject) {
        
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                (allowed) in
                DispatchQueue.main.async {
                    // Run UI Updates
                    if (allowed) {
                        self.performSegue(withIdentifier: Constants.SegueMedicConnectRecordingBroadcast, sender: nil)
                    } else {
                        try? recordingSession.setActive(false)
                        self.processMicrophoneSettings()
                    }
                }
            }
        } catch {
        }
    }
    
    @IBAction func onClose(sender: AnyObject) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = true
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
}
