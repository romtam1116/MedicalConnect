//
//  PatientProfileViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-03.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation

class PatientProfileViewController: BaseViewController {
    
    let OffsetHeaderStop: CGFloat = 180.0
    let PatientNotesCellID = "PatientNotesCell"
    
    var patientId: String? = nil
    var patient: Patient? = nil
    var fromAdd: Bool = false
    var fromNotification: Bool = false
    
    // Header
    @IBOutlet var headerLabel: UILabel!
    
    // Profile info
    @IBOutlet var viewProfileInfo: UIView!
    @IBOutlet var lblPatientName: UILabel!
    @IBOutlet var lblBirthday: UILabel!
    @IBOutlet var lblAddress: UILabel!
    @IBOutlet var lblPhoneNumber: UILabel!
    @IBOutlet var lblPaitentNumber: UILabel!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var btnPatientEdit: UIButton!
    @IBOutlet var btnRecord: UIButton!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var expandedRows = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear Previous Patient Notes
        PostController.Instance.setPatientNotes([])
        
        // Initialize Table Views
        self.tableView.register(UINib(nibName: PatientNotesCellID, bundle: nil), forCellReuseIdentifier: PatientNotesCellID)
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 125.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update UI with basic patient info
        self.updateUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PatientProfileViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refreshData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.releasePlayer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    
    // MARK: Private methods
    
    func refreshData() {
        
        let patientId = self.patient != nil ? self.patient?.id : self.patientId
        if let _patientId = patientId as String? {
            
            // Fetch all patient notes
            PostService.Instance.getNotesByPatientId(id: _patientId, completion: { (success) in
                
                if (success) {
                    self.tableView.reloadData()
                    self.updateScroll(offset: self.mainScrollView.contentOffset.y)
                    
                    if self.fromNotification && PostController.Instance.getPatientNotes().count > 0 {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                            let indexPath = IndexPath.init(row: 0, section: 0)
                            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            self.tableView(self.tableView, didSelectRowAt: indexPath)
                        }
                    }
                }
                
            })
            
        }
        
    }
    
    func updateUI() {
        
        if let _patient = self.patient as Patient? {
            // Customize Patient information
            self.lblPatientName.text = _patient.name
            self.lblBirthday.text = _patient.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
            self.lblAddress.text = _patient.address
            self.lblPhoneNumber.text = _patient.phoneNumber
            self.lblPaitentNumber.text = "PHN # \(_patient.patientNumber)"
            
        } else if let _patientId = self.patientId as String? {
            // Get patient with id
            PatientService.Instance.getPatientById(patientId: _patientId, completion: { (success, patient) in
                if success == true && patient != nil {
                    self.patient = patient
                    
                    self.lblPatientName.text = patient?.name
                    self.lblBirthday.text = patient?.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
                    self.lblAddress.text = patient?.address
                    self.lblPhoneNumber.text = patient?.phoneNumber
                    self.lblPaitentNumber.text = "PHN # \(String(describing: patient?.patientNumber))"
                }
            })
        }
        
        self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        
    }
    
    func releasePlayer(onlyState: Bool = false) {
        
        PlayerController.Instance.invalidateTimer()
        
        // Reset player state
        if let _lastPlayed = PlayerController.Instance.lastPlayed as PlaySlider?,
            let _elapsedLabel = PlayerController.Instance.elapsedTimeLabel as UILabel?,
            let _durationLabel = PlayerController.Instance.durationLabel as UILabel? {
            _lastPlayed.setValue(0.0, animated: false)
            _lastPlayed.playing = false
            _elapsedLabel.text = "0:00"
            _durationLabel.text = "0:00"
        }
        
        if let _observer = PlayerController.Instance.playerObserver as Any? {
            PlayerController.Instance.player?.removeTimeObserver(_observer)
            PlayerController.Instance.playerObserver = nil
            PlayerController.Instance.player?.seek(to: kCMTimeZero)
        }
        
        if let _index = PlayerController.Instance.currentIndex as Int? {
            let post = PostController.Instance.getPatientNotes()[_index]
            post.setPlayed(time: kCMTimeZero, progress: 0.0, setLastPlayed: false)
            
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PatientNotesCell
            cell?.btnPlay.setImage(UIImage.init(named: "icon_playlist_play"), for: .normal)
        }
        
        if onlyState {
            return
        }
        
        // Pause and reset components
        PlayerController.Instance.player?.pause()
        PlayerController.Instance.player = nil
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.elapsedTimeLabel = nil
        PlayerController.Instance.durationLabel = nil
        PlayerController.Instance.currentIndex = nil
        
    }
    
    @objc func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }
        
        guard (self.patient as Patient?) != nil else {
            return
        }
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            _lastPlayed.playing == true {
            self.onPauseAudio(sender: sender)
            return
        }
        
        let post = PostController.Instance.getPatientNotes()[_index]
        
        if let _url = URL(string: post.audio ) as URL? {
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PatientNotesCell
            sender.setImage(UIImage.init(named: "icon_playlist_pause"), for: .normal)
            
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = cell?.playSlider
                PlayerController.Instance.elapsedTimeLabel = cell?.lblElapsedTime
                PlayerController.Instance.durationLabel = cell?.lblDuration
                PlayerController.Instance.shouldSeek = true
                
                _player.rate = 1.0
                _player.play()
                
                PlayerController.Instance.addObserver()
                
            } else {
                
                let playerItem = AVPlayerItem(url: _url)
                PlayerController.Instance.player = AVPlayer(playerItem:playerItem)
                
                if let _player = PlayerController.Instance.player as AVPlayer? {
                    
                    AudioHelper.SetCategory(mode: AudioHelper.overrideMode)
                    
                    PlayerController.Instance.lastPlayed = cell?.playSlider
                    PlayerController.Instance.elapsedTimeLabel = cell?.lblElapsedTime
                    PlayerController.Instance.durationLabel = cell?.lblDuration
                    PlayerController.Instance.currentIndex = _index
                    PlayerController.Instance.shouldSeek = true
                    
                    _player.rate = 1.0
                    _player.play()
                    
                    PlayerController.Instance.addObserver()
                    
                    if Float(_player.currentTime().value) == 0.0 {
                        PostService.Instance.incrementPost(id: post.id, completion: { (success, play_count) in
                            if success, let play_count = play_count {
                                print("Post incremented")
                                post.playCount = play_count
                                // cell?.setData(post: post)
                            }
                        })
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func onPauseAudio(sender: UIButton) {
        
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        sender.setImage(UIImage.init(named: "icon_playlist_play"), for: .normal)
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed as PlaySlider? {
            if let _observer = PlayerController.Instance.playerObserver as Any? {
                PlayerController.Instance.player?.removeTimeObserver(_observer)
                PlayerController.Instance.playerObserver = nil
            }
            
            _lastPlayed.playing = false
            
            guard let _index = sender.tag as Int? else {
                return
            }
            
            guard (self.patient as Patient?) != nil else {
                return
            }
            
            let post = PostController.Instance.getPatientNotes()[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: CGFloat(_lastPlayed.value))
        }
        
    }
    
    @objc func onBackwardAudio(sender: UIButton) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        var time = CMTimeGetSeconds(_player.currentTime())
        if time == 0 { return }
        time = time - 15 >= 0 ? time - 15 : 0
        
        self.seekToTime(time: time)
    }
    
    @objc func onForwardAudio(sender: UIButton) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        var time = CMTimeGetSeconds(_player.currentTime())
        let duration = CMTimeGetSeconds((_player.currentItem?.duration)!)
        if time == duration { return }
        time = time + 15 <= duration ? time + 15 : duration
        
        self.seekToTime(time: time)
    }
    
    @objc func onSeekSlider(sender: UISlider) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        let duration = CMTimeGetSeconds((_player.currentItem?.duration)!)
        let time = duration * Float64(sender.value)
        
        self.seekToTime(time: time)
    }
    
    @objc func onSynopsis(sender: UIButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }
        
        guard (self.patient as Patient?) != nil else {
            return
        }
        
        let post = PostController.Instance.getPatientNotes()[_index]
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
            vc.strTitle = "Transcription"
            vc.strSynopsisUrl = post.transcriptionUrl
            present(vc, animated: true, completion: nil)
            
        }
        
    }
    
    @objc func onSelectSpeaker(sender: UIButton) {
        
        if AudioHelper.overrideMode == .speaker {
            AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.none)
            sender.setImage(UIImage(named: "icon_speaker_off"), for: .normal)
        } else {
            AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
            sender.setImage(UIImage(named: "icon_speaker_on"), for: .normal)
        }
        
    }
    
    func seekToTime(time: Float64) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.seek(to: CMTimeMakeWithSeconds(time, _player.currentTime().timescale), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            let _elapsedLabel = PlayerController.Instance.elapsedTimeLabel,
            _lastPlayed.playing == false {
            
            _lastPlayed.setValue(Float(time / CMTimeGetSeconds((_player.currentItem?.duration)!)), animated: false)
            _elapsedLabel.text = TimeInterval(time).durationText
            
            guard let _index = _lastPlayed.index as Int? else {
                return
            }
            
            guard (self.patient as Patient?) != nil else {
                return
            }
            
            let post = PostController.Instance.getPatientNotes()[_index]
            post.setPlayed(time: CMTimeMakeWithSeconds(time, _player.currentTime().timescale), progress: CGFloat(_lastPlayed.value))
            
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        self.releasePlayer(onlyState: true)
    }
    
    @objc func willEnterBackground() {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        
        if let sender = PlayerController.Instance.lastPlayed {
            sender.playing = false
            guard let _index = sender.index as Int? else {
                return
            }
            
            guard (self.patient as Patient?) != nil else {
                return
            }
            
            let post = PostController.Instance.getPatientNotes()[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: CGFloat(sender.value))
        }
        
        PlayerController.Instance.lastPlayed?.setValue(Float(0.0), animated: false)
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.elapsedTimeLabel?.text = "0:00"
        PlayerController.Instance.elapsedTimeLabel = nil
        PlayerController.Instance.durationLabel?.text = "0:00"
        PlayerController.Instance.durationLabel = nil
        PlayerController.Instance.shouldSeek = true
        PlayerController.Instance.scheduleReset()
        
    }
    
    // MARK: Scroll Ralated
    
    func updateScroll(offset: CGFloat) {
        self.viewProfileInfo.alpha = max (0.0, (OffsetHeaderStop - offset) / OffsetHeaderStop)
        
        // ScrollViews Frame
        if (offset >= OffsetHeaderStop) {
            self.tableViewTopConstraint.constant = offset - OffsetHeaderStop + self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64
            
            self.getCurrentScroll().setContentOffset(CGPoint(x: 0, y: offset - OffsetHeaderStop), animated: false)
        } else {
            self.tableViewTopConstraint.constant = self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64 - self.headerViewHeightConstraint.constant + offset
            self.getCurrentScroll().setContentOffset(CGPoint.zero, animated: false)
        }
        
    }
    
    func getCurrentScroll() -> UIScrollView {
        let scrollView: UIScrollView = self.tableView
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.width, height: max(self.view.frame.height - 64.0 + OffsetHeaderStop, scrollView.contentSize.height + self.headerViewHeightConstraint.constant))
        
        return scrollView
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        if (tableView == self.tableView) {
            if (self.patient as Patient?) != nil {
                return PostController.Instance.getPatientNotes().count
            } else {
                return 0
            }
        }
        
        return 0
    }
    
}

extension PatientProfileViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView Datasource methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tableView {
            tableView.backgroundView = nil
            return 1
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.numberOfRows(inTableView: tableView, section: section)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            
            let cell: PatientNotesCell = tableView.dequeueReusableCell(withIdentifier: PatientNotesCellID, for: indexPath) as! PatientNotesCell
            
            guard (self.patient as Patient?) != nil else {
                return cell
            }
            
            cell.delegate = self
            
            let post = PostController.Instance.getPatientNotes()[indexPath.row]
            cell.setData(post: post)
            
            cell.lblDescription.isUserInteractionEnabled = false
            
            cell.btnSynopsis.tag = indexPath.row
            if post.transcriptionUrl == "" {
                cell.btnSynopsis.removeTarget(self, action: #selector(onSynopsis(sender:)), for: .touchUpInside)
            } else if cell.btnSynopsis.allTargets.count == 0 {
                cell.btnSynopsis.addTarget(self, action: #selector(onSynopsis(sender:)), for: .touchUpInside)
            }
            
            cell.btnSpeaker.tag = indexPath.row
            if cell.btnSpeaker.allTargets.count == 0 {
                cell.btnSpeaker.addTarget(self, action: #selector(onSelectSpeaker(sender:)), for: .touchUpInside)
            }
            
            cell.btnPlay.tag = indexPath.row
            if cell.btnPlay.allTargets.count == 0 {
                cell.btnPlay.addTarget(self, action: #selector(PatientProfileViewController.onPlayAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnBackward.tag = indexPath.row
            if cell.btnBackward.allTargets.count == 0 {
                cell.btnBackward.addTarget(self, action: #selector(PatientProfileViewController.onBackwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnForward.tag = indexPath.row
            if cell.btnForward.allTargets.count == 0 {
                cell.btnForward.addTarget(self, action: #selector(PatientProfileViewController.onForwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.playSlider.index = indexPath.row
            cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
            if cell.playSlider.allTargets.count == 0 {
                cell.playSlider.addTarget(self, action: #selector(PatientProfileViewController.onSeekSlider(sender:)), for: .valueChanged)
            }
            
            cell.isExpanded = self.expandedRows.contains(post.id)
            cell.selectionStyle = .none
            
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    // MARK: UITableView Delegate methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? PatientNotesCell
                else { return }
            
            guard (self.patient as Patient?) != nil else {
                return
            }
            
            self.releasePlayer()
            
            if PlayerController.Instance.lastPlayed == nil {
                cell.playSlider.setValue(0.0, animated: false)
                cell.playSlider.playing = false
            }
            
            let post = PostController.Instance.getPatientNotes()[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)

            case false:
                self.expandedRows.insert(post.id)
            }

            cell.isExpanded = !cell.isExpanded
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? PatientNotesCell
                else { return }
            
            guard (self.patient as Patient?) != nil else {
                return
            }
            
            let post = PostController.Instance.getPatientNotes()[indexPath.row]
            self.expandedRows.remove(post.id)
            
            cell.isExpanded = false
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
    }
    
}

extension PatientProfileViewController : UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            let offset: CGFloat = scrollView.contentOffset.y
            
            if offset >= 0 { // PULL DOWN -----------------
                self.updateScroll(offset: offset)
            }
        }
        
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
        }
        
    }
    
}

extension PatientProfileViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        if let _nav = self.navigationController as UINavigationController? {
            if self.fromAdd == true {
                _nav.popToRootViewController(animated: false)
            } else {
                _nav.popViewController(animated: false)
            }
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onPatientEdit(sender: AnyObject!) {
        // Show Edit Patient Screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "EditPatientViewController") as? EditPatientViewController {
            vc.patient = self.patient
            self.navigationController?.pushViewController(vc, animated: false)
        }
        
    }
    
    @IBAction func onRecord(sender: AnyObject!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: (patient?.id)!)
            DataManager.Instance.setPatient(patient: patient)
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
            DataManager.Instance.setReferringUserMSP(referringUserMSP: "")
            DataManager.Instance.setFromPatientProfile(true)
            
            self.present(vc, animated: false, completion: {
                
            })
            
        }
    }
    
}

extension PatientProfileViewController: PatientNotesCellDelegate {
    
    func patientNotesCellDidTapReferringUser(_ user: User) {
        // Show referring user profile
        if  let _me = UserController.Instance.getUser() as User? {
            if _me.id == user.id {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if  let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
                
                if let blockedby = _me.blockedby as? [User] {
                    if blockedby.contains(where: { $0.id == user.id }) {
                        return
                    }
                }
                if let blocking = _me.blocking as? [User] {
                    if blocking.contains(where: { $0.id == user.id }) {
                        return
                    }
                }
                
                vc.currentUser = user
                self.present(vc, animated: false, completion: nil)
                
            }
        }
    }
    
}
