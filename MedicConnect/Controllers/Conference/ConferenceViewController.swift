//
//  ConferenceViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import IQKeyboardManager

class ConferenceViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    let HistoryCellID = "HistoryListCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tvHistory: UITableView!
    
    @IBOutlet var constOfTableViewBottom: NSLayoutConstraint!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var searchedHistory: [History] = []
    
    var call: SINCall? = nil
//    {
//        didSet {
//            call?.delegate = self
//        }
//    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vcDisappearType = .other
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive , object: nil)
        
        self.clearBadges()
        self.loadHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear search field and results
        self.txFieldSearch.text = ""
        self.loadSearchResult(self.txFieldSearch.text!)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.initViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearBadges() {
//        let badgeValue = self.navigationController?.tabBarItem.badgeValue == nil ? 0 : Int((self.navigationController?.tabBarItem.badgeValue)!)!
//        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber > badgeValue ? UIApplication.shared.applicationIconBadgeNumber - badgeValue : 0
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        self.navigationController?.tabBarItem.badgeValue = nil
        UserDefaultsUtil.SaveMissedCalls("")
    }
    
    @objc func willEnterForeground(){
        self.clearBadges()
        self.loadHistory()
    }
    
}

extension ConferenceViewController {
    // SINCallClientDelegate, SINCallDelegate
    
    // MARK: Private methods
    
    func initViews() {
        // Initialize Table Views
        
        let nibPatientCell = UINib(nibName: HistoryCellID, bundle: nil)
        self.tvHistory.register(nibPatientCell, forCellReuseIdentifier: HistoryCellID)
        
        self.tvHistory.tableFooterView = UIView()
        self.tvHistory.rowHeight = 65.0
//        self.tvHistory.estimatedRowHeight = 65.0
//        self.tvHistory.rowHeight = UITableViewAutomaticDimension
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            constOfTableViewBottom.constant = bottomMargin
            
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        constOfTableViewBottom.constant = 0
        
        UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func loadHistory() {
        // Load History

        HistoryService.Instance.getCallHistory { (success: Bool) in
            self.loadSearchResult(self.txFieldSearch.text!)
        }
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchedHistory = HistoryController.Instance.getHistories()
        } else {
            searchedHistory = HistoryController.Instance.getHistories().filter({(history: History) -> Bool in
                return history.fromUser.fullName.lowercased().contains(keyword.lowercased()) ||
                    history.fromUser.location.lowercased().contains(keyword.lowercased())
            })
        }
        
        self.tvHistory.reloadData()
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    // MARK: - SINCallDelegate
    /*
    func callDidProgress(_ call: SINCall!) {
        self.audioController?.startPlayingSoundFile(self.pathForSound("ringback.wav"), loop: true)
        
        self.callShouldSendAlert = true
        
        // Define Call Task
        self.callTask = DispatchWorkItem.init(block: {
            self.call?.hangup()
        })
        
        // Execute call task in 20 seconds
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 20, execute: callTask!)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        // Cancel call task
        if self.callTask != nil && !(self.callTask?.isCancelled)! {
            self.callTask?.cancel()
        }
        
        self.callShouldEnd = true
        
        self.audioController?.disableSpeaker()
        
        if self.call?.details.isVideoOffered == false {
            self.startCallDurationTimerWithSelector(#selector(onDurationTimer(_:)))
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.audioController?.enableSpeaker()
            }
            
            // Disable idle timer
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        self.showButtons(.kButtonsHangup)
        self.audioController?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        // Cancel call task
        if self.callTask != nil && !(self.callTask?.isCancelled)! {
            self.callTask?.cancel()
        }
        
        if self.callShouldSendAlert && call.details.endCause != SINCallEndCause.hungUp {
            // Call misssed
            NotificationService.Instance.sendMissedCallAlert(toUser: self.consulterId!) { (success) in
                // Do nothing
            }
        }
        
        if self.callShouldEnd || self.callStep == 3 {
            self.audioController?.stopPlayingSoundFile()
            self.audioController?.disableSpeaker()
            self.stopCallDurationTimer()
            self.stopHideDurationTimer()
            
            if (self.call?.details.isVideoOffered)! {
                self.videoController?.remoteView().removeFromSuperview()
            }
            
            // Disable idle timer
            UIApplication.shared.isIdleTimerDisabled = false
            
            self.dismiss(animated: true, completion: nil)
            self.presentingViewController?.dismiss(animated: false, completion: nil)
        } else {
            // Show routing state
            self.setCallStatusText("ROUTING...")
            self.lblRemoteUserName.text = ""
            
            // Get consulting doctors from server
            ConsultService.Instance.getConsultingDoctors { (success) in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        self.startCall(self.isVideo)
                    }
                } else {
                    // Finish screen
                    self.callShouldEnd = true
                    self.callShouldSendAlert = false
                    self.callDidEnd(self.call!)
                }
            }
        }
        
    }
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        self.videoController?.remoteView().frame = UIScreen.main.bounds
        self.videoController?.remoteView().contentMode = .scaleAspectFill
        self.viewRemoteVideo.addSubview((self.videoController?.remoteView())!)
    }
    
    func call(_ call: SINCall!, shouldSendPushNotifications pushPairs: [Any]!) {
        
    }
    */
    // MARK: Selectors
    
}

extension ConferenceViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.searchedHistory.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HistoryListCell = tableView.dequeueReusableCell(withIdentifier: HistoryCellID) as! HistoryListCell
        let history = self.searchedHistory[indexPath.row]
        
        cell.setData(history)
        
//        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.imgUserPhoto.addGestureRecognizer(tapGestureOnUserAvatar)
//        cell.imgUserPhoto.tag = indexPath.row
        
//        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.lblDoctorName.addGestureRecognizer(tapGestureOnUsername)
//        cell.lblDoctorName.tag = indexPath.row
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let history = self.searchedHistory[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if  let vc = storyboard.instantiateViewController(withIdentifier: "CallMakeScreenViewController") as? CallMakeScreenViewController {
            vc.callReceiver = history.fromUser
            self.present(vc, animated: false, completion: nil)
        }

        
//        guard let _patient = self.searchedPatients[indexPath.row] as Patient? else {
//            return
//        }

//        let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
//        patientProfileVC.patient = _patient
//        patientProfileVC.fromAdd = false
//        self.navigationController?.pushViewController(patientProfileVC, animated: true)
    }
    
}

extension ConferenceViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
}

extension ConferenceViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        if (CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: txtAfterUpdate as String)) && txtAfterUpdate.length > Constants.MaxPHNLength) {
            return false
        }
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}
