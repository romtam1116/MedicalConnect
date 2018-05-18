//
//  EditRecordingBroadcastViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/4/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import Foundation
import AVFoundation

class EditRecordingBroadcastViewController: BaseViewController {
    
    @IBOutlet var mSlider: RecordSlider!
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var labelLength: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnSpeaker: UIButton!
    
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var updateTimer: Timer?
    fileprivate var fromDelete: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        self.play()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.audioPlayer != nil && self.audioPlayer?.isPlaying == false) {
            self.btnPause.isHidden = true
            self.btnPlay.isHidden = false
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    @objc func willEnterForeground(){
        if (self.audioPlayer != nil && self.audioPlayer?.isPlaying == false) {
            self.btnPause.isHidden = true
            self.btnPlay.isHidden = false
        }
    }
    
    @objc func willEnterBackground(){
        if (self.audioPlayer != nil) {
            
            self.btnPause.isHidden = false
            self.btnPlay.isHidden = true
            self.audioPlayer?.stop()
            self.updateTimer?.invalidate()
        }
    }
    
    //MARK: Initialize views
    
    func initViews() {
        
        // Slider
        self.mSlider.setThumbImage(UIImage(named: "icon_recording_slider_pin"), for: .normal)
        self.mSlider.setThumbImage(UIImage(named: "icon_recording_slider_pin"), for: .highlighted)
        self.mSlider.setThumbImage(UIImage(named: "icon_recording_slider_pin"), for: .selected)
        self.mSlider.value = self.mSlider.minimumValue
        
    }
    
    func play() {
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            
            if let _audioPlayer = self.audioPlayer as AVAudioPlayer? {
                self.mSlider.minimumValue = 0
                self.mSlider.maximumValue = Float(_audioPlayer.duration)
                let dTotalSeconds = _audioPlayer.duration
                self.labelLength.text = dTotalSeconds.durationText
                
                DataManager.Instance.setRecordDuration(recordDuration: Int(dTotalSeconds.rounded(.awayFromZero)))
                
                AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
                _audioPlayer.prepareToPlay()
                _audioPlayer.play()
                _audioPlayer.delegate = self
                
                self.updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditRecordingBroadcastViewController.updateSeekBar), userInfo: nil, repeats: true)
            }
            
        } catch {
            print("Failed to play audio")
        }
        
    }
    
    func stop() {
        if (self.audioPlayer != nil && self.audioPlayer!.isPlaying) {
            self.audioPlayer!.stop()
            self.audioPlayer = nil
            
            self.updateTimer?.invalidate()
            self.updateTimer = nil
        }
    }
    
    @objc func updateSeekBar() {
        
        if let _audioPlayer = self.audioPlayer as AVAudioPlayer? {
            let progress = _audioPlayer.currentTime
            self.mSlider.setValue(Float(progress), animated: true)
            self.lblCurrentTime.text = progress.durationText
        }
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}

extension EditRecordingBroadcastViewController {
    
    //MARK: IBActions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    @IBAction func onClose(sender: UIButton) {
        self.stop()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = true
        
        if let _nav = self.navigationController as UINavigationController? {
            if fromDelete {
                _nav.popToRootViewController(animated: false)
            } else {
                _nav.dismiss(animated: false, completion: nil)
            }
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSeek(sender: UIButton) {
        
        if let _audioPlayer = self.audioPlayer as AVAudioPlayer? {
            _audioPlayer.currentTime = TimeInterval(self.mSlider.value)
        }
        
    }
    
    @IBAction func onRewind(_ sender: Any) {
        
        if (self.audioPlayer != nil) {
            self.audioPlayer?.currentTime = 0
        }
        
    }
    
    @IBAction func onForward(_ sender: Any) {
        
        if (self.audioPlayer != nil) {
            self.audioPlayer?.currentTime = (self.audioPlayer?.currentTime)! + 15
        }
        
    }
    
    @IBAction func onPlay(_ sender: Any) {
        
        self.audioPlayer?.play()
        self.updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditRecordingBroadcastViewController.updateSeekBar), userInfo: nil, repeats: true)
        
        self.btnPlay.isHidden = true
        self.btnPause.isHidden = false
        
    }
    
    @IBAction func onPause(_ sender: Any) {
        
        self.audioPlayer?.pause()
        self.updateTimer?.invalidate()
        
        self.btnPlay.isHidden = false
        self.btnPause.isHidden = true
        
    }
    
    @IBAction func onDelete(sender: UIButton) {
        
        AlertUtil.showConfirmAlert(self, title: NSLocalizedString("Are you sure you want to delete recording?", comment: "comment"), message: nil, okButtonTitle: NSLocalizedString("I'M SURE", comment: "comment"), cancelButtonTitle: NSLocalizedString("NEVER MIND", comment: "comment"), okCompletionBlock: {
            // OK completion block
            self.fromDelete = true
            self.onClose(sender: UIButton())
        }, cancelCompletionBlock: {
            // Cancel completion block
        })
        
    }
    
    @IBAction func onSave(sender: UIButton) {
        self.stop()
        
        if DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis {
            self.performSegue(withIdentifier: Constants.SegueMedicConnectSaveDiagnosis, sender: nil)
        } else {
            self.performSegue(withIdentifier: Constants.SegueMedicConnectSaveConsult, sender: nil)
        }
        
    }
    
    @IBAction func onContinueRecording(sender: UIButton) {
        self.stop()
        self.navigationController?.popViewController(animated: false)
        
    }
    
    @IBAction func onSelectSpeaker(sender: UIButton) {
        
        if AudioHelper.overrideMode == .speaker {
            AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.none)
            sender.setImage(UIImage(named: "icon_speaker_off"), for: .normal)
        } else {
            AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
            sender.setImage(UIImage(named: "icon_speaker_on"), for: .normal)
        }
        
    }
    
}

extension EditRecordingBroadcastViewController : AVAudioPlayerDelegate {
    // AVAudioPlayer delegate methods
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        self.btnPlay.isHidden = false
        self.btnPause.isHidden = true
        
        self.updateTimer?.invalidate()
        
    }
}

class RecordSlider: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 3
        return newBounds
    }
    
}
