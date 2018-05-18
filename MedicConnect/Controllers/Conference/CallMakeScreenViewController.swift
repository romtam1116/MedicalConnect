//
//  CallMakeScreenViewController.swift
//  MedicalConsult
//
//  Created by Juan on 5/15/18.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import UIKit
import FXBlurView

class CallMakeScreenViewController: UIViewController, SINCallClientDelegate, SINCallDelegate {

    @IBOutlet weak var mBackgroundImageView: UIImageView!
    @IBOutlet weak var blurView: FXBlurView!
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var lblCallState: UILabel!
    @IBOutlet weak var lblRemoteUserName: UILabel!
    
    // Buttons
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnSwitchCamera: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    
    // Video Views
    @IBOutlet weak var viewLocalContainer: UIView!
    @IBOutlet weak var viewLocalVideo: UIView!
    @IBOutlet weak var viewRemoteVideo: UIView!
    
    var receiverId: String? = nil
    
    var activityIndicatorView = UIActivityIndicatorView()
    
    var durationTimer: Timer?
    var speakerEnabled: Bool = false
    var muted: Bool = false
    var isVideo: Bool = false
    var callReceiver: User? = nil

    var callShouldSendAlert: Bool = true
    
    private var hideControls: Bool = false
    private var hideTimer: Timer?
    
    var audioController: SINAudioController? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.sinchClient?.audioController()
    }
    
    var videoController: SINVideoController? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.sinchClient?.videoController()
    }
    
    var call: SINCall? = nil {
        didSet {
            call?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable playing audio in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.allowBluetoothA2DP)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print("Failed to enable playing audio in silent mode")
        }
        
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        // Local video border color
        self.viewLocalVideo.layer.borderColor = UIColor.init(red: 147/255.0, green: 203/255.0, blue: 202/255.0, alpha: 1.0).cgColor
        
        self.showButtons(.kButtonsCall)
        
        // Call Video
        self.startCall(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get consulting doctor
        //        self.getConsultingDoctor()
        
        self.audioController?.disableSpeaker()
        self.audioController?.unmute()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.call?.details.isVideoOffered == true {
            AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Private Methods
    func pathForSound(_ soundName: String) -> String {
        return Bundle.main.resourceURL!.appendingPathComponent(soundName).path
    }
    
    @objc func onDurationTimer(_ unused: Timer) {
        let duration: Int = Int(Date().timeIntervalSince((self.call?.details.establishedTime)!))
        self.setDuration(duration)
    }
    
    @objc func onViewTapped(sender: UITapGestureRecognizer) {
        self.stopHideDurationTimer()
        self.hideControls = !self.hideControls
        if self.hideControls == false {
            self.startHideTimerWithSelector()
        }
        
        DispatchQueue.main.async {
            self.showHideControls()
        }
    }
    
    // MARK: - SINCallDelegate
    
    func callDidProgress(_ call: SINCall!) {
        self.audioController?.startPlayingSoundFile(self.pathForSound("ringback.wav"), loop: true)
        self.callShouldSendAlert = true
    }
    
    func callDidEstablish(_ call: SINCall!) {
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
        if self.callShouldSendAlert && call.details.endCause != SINCallEndCause.hungUp {
            // Call misssed
            NotificationService.Instance.sendMissedCallAlert(toUser: self.receiverId!) { (success) in
                // Do nothing
            }
        }

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
    }
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        self.videoController?.remoteView().frame = UIScreen.main.bounds
        self.videoController?.remoteView().contentMode = .scaleAspectFill
        self.viewRemoteVideo.addSubview((self.videoController?.remoteView())!)
    }
    
    func call(_ call: SINCall!, shouldSendPushNotifications pushPairs: [Any]!) {
        
    }
    
}

extension CallMakeScreenViewController {
    
    // MARK: - UI Methods
    
    fileprivate func startIndicating(){
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    fileprivate func stopIndicating() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.removeFromSuperview()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    fileprivate func setCallStatusText(_ text: String) {
        self.lblCallState.text = text
    }
    
    fileprivate func setDuration(_ seconds: Int) {
        self.setCallStatusText(String.init(format: "%02d:%02d", arguments: [Int(seconds / 60), Int(seconds % 60)]))
    }
    
    fileprivate func showButtons(_ buttons: EButtonsBar) {
        if buttons == .kButtonsCall {
            self.viewLocalContainer.isHidden = true
            self.viewRemoteVideo.isHidden = true
            
            self.lblCallState.isHidden = true
            self.lblRemoteUserName.isHidden = true
            
            self.btnSwitchCamera.isHidden = true
            self.btnSpeaker.isHidden = true
            self.btnMute.isHidden = true
            self.btnEnd.isHidden = true
            
        } else if buttons == .kButtonsAnswerDecline {
            self.maskView.alpha = 0.35
            self.setCallStatusText("CALLING")
            
            // Customize Avatar
            self.lblRemoteUserName.text = self.callReceiver?.fullName
            
            self.lblCallState.isHidden = false
            self.lblRemoteUserName.isHidden = false
            
            self.btnClose.isHidden = true
            self.btnCall.isHidden = true
            self.btnEnd.isHidden = false
            
        } else if buttons == .kButtonsHangup {
            if (self.call?.details.isVideoOffered)! {
                // Video Call
                self.videoController?.localView().contentMode = .scaleAspectFill
                self.viewLocalVideo.addSubview((self.videoController?.localView())!)
                
                self.viewLocalContainer.isHidden = false
                self.viewRemoteVideo.isHidden = false
                self.btnSwitchCamera.isHidden = false
                
                self.viewRemoteVideo.backgroundColor = UIColor.black
                
                self.mBackgroundImageView.isHidden = true
                self.blurView.isHidden = true
                self.maskView.isHidden = true
                
                self.lblCallState.isHidden = true
                self.lblRemoteUserName.isHidden = true
                
                // Enable landscape mode
                AppDelegate.AppUtility.lockOrientation(.all)
            }
            
            self.speakerEnabled = (self.call?.details.isVideoOffered)!
            if self.speakerEnabled {
                self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker_on"), for: .normal)
            } else {
                self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker"), for: .normal)
            }
            
            self.btnSpeaker.isHidden = false
            self.btnMute.isHidden = false
            
            let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(onViewTapped(sender:)))
            self.view.addGestureRecognizer(tapGesture)
            self.view.isUserInteractionEnabled = true
            
            self.hideControls = false
            self.startHideTimerWithSelector()
        }
    }
    
    fileprivate func showHideControls() {
        
        if (self.call?.details.isVideoOffered)! {
            self.btnSwitchCamera.isHidden = self.hideControls
        }
        
        self.btnSpeaker.isHidden = self.hideControls
        self.btnMute.isHidden = self.hideControls
        self.btnEnd.isHidden = self.hideControls
        
    }
    
    @objc fileprivate func internal_updateDuration(_ timer: Timer) {
        let selector: Selector = NSSelectorFromString(timer.userInfo as! String)
        if self.responds(to: selector) {
            self.perform(selector, with: timer)
        }
    }
    
    fileprivate func startCallDurationTimerWithSelector(_ sel: Selector) {
        let selectorAsString: String = NSStringFromSelector(sel)
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                  target: self,
                                                  selector: #selector(internal_updateDuration(_:)),
                                                  userInfo: selectorAsString,
                                                  repeats: true)
    }
    
    fileprivate func stopCallDurationTimer() {
        self.durationTimer?.invalidate()
        self.durationTimer = nil
    }
    
    fileprivate func startHideTimerWithSelector() {
        self.hideTimer = Timer.scheduledTimer(withTimeInterval: 5.5,
                                              repeats: false,
                                              block: { (timer) in
                                                self.hideControls = true
                                                DispatchQueue.main.async {
                                                    self.showHideControls()
                                                }
        })
    }
    
    fileprivate func stopHideDurationTimer() {
        if (self.hideTimer != nil) {
            self.hideTimer?.invalidate()
            self.hideTimer = nil
        }
    }
    
    func startCall(_ isVideo: Bool) {
        // Start audio/video call
        self.isVideo = isVideo
        
        if let _user = self.callReceiver as User? {
            print("Calling Doctor: \(_user.id)")
            self.receiverId = _user.id
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.shouldReceiveCall = false

            if isVideo {
                self.call = appDelegate.sinchClient?.call().callUserVideo(withId: "5af4fb894920576fd7a5f92d"/*_user.id*/)
            } else {
                self.call = appDelegate.sinchClient?.call().callUser(withId: _user.id)
            }
            
            self.showButtons(.kButtonsAnswerDecline)

        } else {
            // Finish screen
            self.callShouldSendAlert = false
            self.callDidEnd(self.call!)
        }
        
    }
    
}

extension CallMakeScreenViewController {
    
    // MARK: - IBActions
    
    @IBAction func onClose(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onCall(sender: AnyObject) {
        // Present AlertController
        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        let audioAction = UIAlertAction.init(title: "CALL AUDIO", style: .default) { (action) in
            // Call Audio
            if (self.callReceiver as User?) != nil {
                self.startCall(false)
            } else {
                AlertUtil.showSimpleAlert(self, title: "Receiver is not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        audioAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        audioAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        audioAction.setValue(UIImage(named:"icon_audio")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(audioAction)
        
        let videoAction = UIAlertAction.init(title: "CALL VIDEO", style: .default) { (action) in
            // Call Video
            if (self.callReceiver as User?) != nil {
                self.startCall(true)
            } else {
                AlertUtil.showSimpleAlert(self, title: "Receiver is not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        videoAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        videoAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        videoAction.setValue(UIImage(named:"icon_video")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(videoAction)
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel)
        cancelAction.setValue(UIColor.init(red: 143/255.0, green: 195/255.0, blue: 196/255.0, alpha: 1), forKey: "titleTextColor")
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        // Update AlertController Style
        let actionViews = alertController.view.value(forKey: "actionViews") as! [UIView]
        if actionViews.count > 0 {
            let audioView = actionViews[0] as UIView
            (audioView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 80
            
            let videoView = actionViews[1] as UIView
            (videoView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 80
        }
        
    }
    
    @IBAction func onSwitchCamera(sender: AnyObject) {
        self.videoController?.captureDevicePosition = SINToggleCaptureDevicePosition((self.videoController?.captureDevicePosition)!);
    }
    
    @IBAction func onSpeaker(sender: AnyObject) {
        self.speakerEnabled = !self.speakerEnabled
        
        if self.speakerEnabled {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker_on"), for: .normal)
            self.audioController?.enableSpeaker()
        } else {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker"), for: .normal)
            self.audioController?.disableSpeaker()
        }
    }
    
    @IBAction func onMute(sender: AnyObject) {
        self.muted = !self.muted
        
        if self.muted {
            self.btnMute.setImage(UIImage(named: "icon_muted"), for: .normal)
            self.audioController?.mute()
        } else {
            self.btnMute.setImage(UIImage(named: "icon_mute"), for: .normal)
            self.audioController?.unmute()
        }
    }
    
    @IBAction func onEndCall(sender: AnyObject) {
        self.call?.hangup()
    }

}
