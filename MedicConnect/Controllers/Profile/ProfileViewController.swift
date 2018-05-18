//
//  ProfileViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation
import Crashlytics

class ProfileViewController: BaseViewController {
    
    let OffsetHeaderStop: CGFloat = 190.0
    let ProfileListCellID = "ProfileListCell"
    
    // Header
    @IBOutlet var headerLabel: UILabel!
    
    // Profile info
    @IBOutlet var viewProfileInfo: UIView!
    @IBOutlet var imgAvatar: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblLocation: UILabel!
    @IBOutlet var lblTitle: UILabel!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var btnRecord: UIButton!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var activityIndicatorView = UIActivityIndicatorView()
    
    var firstLoad: Bool = true
    var postType: String = Constants.PostTypeConsult
    var vcDisappearType : ViewControllerDisappearType = .other
    var expandedRows = Set<String>()
    var selectedRowIndex = -1
    
    var menuButton: ExpandingMenuButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (UIApplication.shared.applicationIconBadgeNumber > 0) {
            NotificationUtil.updateNotificationAlert(hasNewAlert: true)
        }
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.tabBarController = self.tabBarController as? RadTabBarController
        
        let tabBarItem = self.tabBarController?.tabBar.items![0]
        tabBarItem?.badgeValue = UserDefaultsUtil.LoadMissedCalls() == "" ? nil : UserDefaultsUtil.LoadMissedCalls()
        
        // Register Device Token
//        if let _me = UserController.Instance.getUser() as User?, let deviceToken = UserController.Instance.getDeviceToken() as String?, deviceToken != _me.deviceToken {
//            UserService.Instance.putDeviceToken(deviceToken: deviceToken) { (success) in
//                if (success) {
//                    _me.deviceToken = deviceToken
//                }
//            }
//        }
        
        // Initialize Table Views
        self.tableView.register(UINib(nibName: ProfileListCellID, bundle: nil), forCellReuseIdentifier: ProfileListCellID)
        self.tableView.tableFooterView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 50.0))
        self.tableView.estimatedRowHeight = 110.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
//        configureExpandingMenuButton()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.updatedProfileSettings), name: updatedProfileNotification, object: nil)
        nc.addObserver(self, selector: #selector(self.updateTab), name: NSNotification.Name(rawValue: NotificationDidRecordingFinish), object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.initViews()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.selectedRowIndex = (self.tableView.indexPathForSelectedRow != nil) ? self.tableView.indexPathForSelectedRow!.row : -1
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
        
        if (vcDisappearType == .other || vcDisappearType == .record) {
            self.releasePlayer()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Private methods
    
    func initViews() {
        
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        self.updateUI()
        self.loadAll()
        
        if (!self.firstLoad) {
            self.refreshData()
        }
        
        self.firstLoad = false
        
    }
    
    fileprivate func configureExpandingMenuButton() {
        self.btnRecord.isHidden = true
        
        let tabBarHeight = UIScreen.main.nativeBounds.height == 2436 ? CGFloat(TABBAR_HEIGHT) + 26.0 : CGFloat(TABBAR_HEIGHT)
        let menuButtonSize: CGSize = CGSize(width: 58.0, height: 58.0)
        self.menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize), centerImage: UIImage(named: "icon_profile_add")!, centerHighlightedImage: UIImage(named: "icon_profile_add")!)
        menuButton!.center = CGPoint(x: self.view.bounds.width - 44.0, y: self.view.bounds.height - 34.0 - tabBarHeight)
        self.view.addSubview(menuButton!)
        
        let item1 = ExpandingMenuItem(size: CGSize(width: 50.0, height: 50.0), title: "Record New Consult", image: UIImage(named: "icon_record_consult")!, highlightedImage: UIImage(named: "icon_record_consult")!, backgroundImage: nil, backgroundHighlightedImage: nil) { () -> Void in
            // Consult
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
                
                DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
                DataManager.Instance.setPatientId(patientId: "")
                DataManager.Instance.setPatient(patient: nil)
                DataManager.Instance.setFromPatientProfile(false)
                
                self.present(vc, animated: false, completion: nil)
                
            }
        }
        
        let item2 = ExpandingMenuItem(size: CGSize(width: 50.0, height: 50.0), title: "Record New Diagnosis", image: UIImage(named: "icon_record_diagnosis")!, highlightedImage: UIImage(named: "icon_record_diagnosis")!, backgroundImage: nil, backgroundHighlightedImage: nil) { () -> Void in
            // Diagnosis
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
                
                DataManager.Instance.setPostType(postType: Constants.PostTypeDiagnosis)
                DataManager.Instance.setPatientId(patientId: "")
                DataManager.Instance.setPatient(patient: nil)
                DataManager.Instance.setReferringUserIds(referringUserIds: [])
                DataManager.Instance.setReferringUserMSP(referringUserMSP: "")
                
                self.present(vc, animated: false, completion: nil)
                
            }
        }
        
        menuButton!.addMenuItems([item1, item2])
        
        menuButton!.willPresentMenuItems = { (menu) -> Void in
            self.vcDisappearType = .record
            self.releasePlayer()
            
            self.menuButton!.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(self.menuButton!)
        }
        
        menuButton!.didDismissMenuItems = { (menu) -> Void in
            self.menuButton!.removeFromSuperview()
            self.view.addSubview(self.menuButton!)
        }
    }
    
    func loadAll() {
        
        UserService.Instance.getAll(name: "", completion: {
            (success: BaseTaskController.Response) in
            
        })
        
        NotificationService.Instance.getNotifications { (success) in
            print("notification: \(success)")
        }
        
        PatientService.Instance.getPatients(completion: { (success: Bool) in
            
        })
        
    }
    
    func refreshData() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _user = user as User? {
                self.selectedRowIndex = (self.tableView.indexPathForSelectedRow != nil) ? self.tableView.indexPathForSelectedRow!.row : -1
                
                self.logUser(user: _user)
                self.tableView.reloadData()
                self.updateScroll(offset: self.mainScrollView.contentOffset.y)
            }
        })
        
    }
    
    @objc func updatedProfileSettings() {
        refreshData()
    }
    
    @objc func updateTab() {
        if (DataManager.Instance.getPostType() != Constants.PostTypeNote && self.postType != DataManager.Instance.getPostType()) {
            self.postType = DataManager.Instance.getPostType()
            self.expandedRows = Set<String>()
            self.tableView.reloadData()
            self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        }
    }
    
    func updateUI() {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            // Customize Avatar
            _ = UIFont(name: "Avenir-Heavy", size: 18.0) as UIFont? ?? UIFont.systemFont(ofSize: 18.0)
            
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                         text: _user.getInitials(),
                                                                                         font: UIFont(name: "Avenir-Book", size: 44)!,
                                                                                         size: CGSize(width: 98, height: 98))
            }
            
            // Customize User information
            self.lblUsername.text = "\(_user.fullName)"
            self.lblLocation.text = _user.location
            self.lblTitle.text = _user.title
            
        }
        
    }
    
    func logUser(user : User) {
        // TODO: Use the current user's information
        // You can call any combination of these three methods
        Crashlytics.sharedInstance().setUserEmail(user.email)
        Crashlytics.sharedInstance().setUserIdentifier(user.id)
        Crashlytics.sharedInstance().setUserName(user.fullName)
    }
    
    func markAllAsRead() {
        // Clear notification state
        UIApplication.shared.applicationIconBadgeNumber = 0
        NotificationUtil.updateNotificationAlert(hasNewAlert: false)
        
        NotificationService.Instance.markAllAsRead(completion: { (allRead) in
            if (allRead) {
                
            }
        })
    }
    
    // MARK: Player Functions
    
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
        
        if let _user = UserController.Instance.getUser() as User?,
            let _index = PlayerController.Instance.currentIndex as Int? {
            let post = _user.getPosts(type: self.postType)[_index]
            post.setPlayed(time: kCMTimeZero, progress: 0.0, setLastPlayed: false)
            
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell
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
    
    @objc func onPlayAudio(sender: UIButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            _lastPlayed.playing == true {
            self.onPauseAudio(sender: sender)
            return
        }
        
        let post = _user.getPosts(type: self.postType)[_index]
        
        if let _url = URL(string: post.audio ) as URL? {
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
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
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        let post = _user.getPosts(type: self.postType)[_index]
        if post.transcriptionUrl == "" {
            // Synopsis Not Exists
            if post.orderNumber == "" {
                // No order yet
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShareBroadcastViewController") as? ShareBroadcastViewController {
                    DataManager.Instance.setPostType(postType: post.postType)
                    vc.postId = post.id
                    vc.fromList = true
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
            
        } else {
            // Synopsis Exists
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
                vc.strTitle = "Transcription"
                vc.strSynopsisUrl = post.transcriptionUrl
                present(vc, animated: true, completion: nil)
            }
        }
        
    }
    
    @objc func onSelectPatient(sender: UITapGestureRecognizer) {
        guard let _index = sender.view?.tag as Int? else {
            return
        }
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        let post = _user.getPosts(type: self.postType)[_index]
        if let _patient = PatientController.Instance.findPatientById(post.patientId) {
            
            let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
            patientProfileVC.patient = _patient
            patientProfileVC.fromAdd = false
            self.navigationController?.pushViewController(patientProfileVC, animated: true)
            
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
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
    
    @objc func willEnterForeground(){
        self.refreshData()
        
        let tabBarItem = self.tabBarController?.tabBar.items![0]
        tabBarItem?.badgeValue = UserDefaultsUtil.LoadMissedCalls() == "" ? nil : UserDefaultsUtil.LoadMissedCalls()
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
    
    // MARK: Activity Indicator
    
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
    
}

extension ProfileViewController : UITableViewDataSource, UITableViewDelegate {

    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            if let _user = UserController.Instance.getUser() as User? {
                return _user.getPosts(type: self.postType).count
            }
        }
        
        return 0
        
    }
    
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
            
            let cell: ProfileListCell = tableView.dequeueReusableCell(withIdentifier: ProfileListCellID, for: indexPath) as! ProfileListCell
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return cell
            }
            
            cell.delegate = self
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            cell.setData(post: post)
            
            if post.patientId != "" {
                let tapGestureOnPatient = UITapGestureRecognizer(target: self, action: #selector(onSelectPatient(sender:)))
                cell.lblBroadcast.addGestureRecognizer(tapGestureOnPatient)
                cell.lblBroadcast.tag = indexPath.row
                cell.lblBroadcast.isUserInteractionEnabled = true
            } else {
                for recognizer in cell.lblBroadcast.gestureRecognizers ?? [] {
                    cell.lblBroadcast.removeGestureRecognizer(recognizer)
                }
                cell.lblBroadcast.isUserInteractionEnabled = false
            }
            
            cell.lblDescription.isUserInteractionEnabled = false
            
            cell.btnSynopsis.tag = indexPath.row
            if cell.btnSynopsis.allTargets.count == 0 {
                cell.btnSynopsis.addTarget(self, action: #selector(ProfileViewController.onSynopsis(sender:)), for: .touchUpInside)
            }
            
            cell.btnSpeaker.tag = indexPath.row
            if cell.btnSpeaker.allTargets.count == 0 {
                cell.btnSpeaker.addTarget(self, action: #selector(onSelectSpeaker(sender:)), for: .touchUpInside)
            }
            
            cell.btnPlay.tag = indexPath.row
            if cell.btnPlay.allTargets.count == 0 {
                cell.btnPlay.addTarget(self, action: #selector(ProfileViewController.onPlayAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnBackward.tag = indexPath.row
            if cell.btnBackward.allTargets.count == 0 {
                cell.btnBackward.addTarget(self, action: #selector(ProfileViewController.onBackwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnForward.tag = indexPath.row
            if cell.btnForward.allTargets.count == 0 {
                cell.btnForward.addTarget(self, action: #selector(ProfileViewController.onForwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.playSlider.index = indexPath.row
            cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
            if cell.playSlider.allTargets.count == 0 {
                cell.playSlider.addTarget(self, action: #selector(ProfileViewController.onSeekSlider(sender:)), for: .valueChanged)
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
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            self.releasePlayer()
            
            if PlayerController.Instance.lastPlayed == nil {
                cell.playSlider.setValue(0.0, animated: false)
                cell.playSlider.playing = false
            }
            
            self.tableView.beginUpdates()

            let post = _user.getPosts(type: self.postType)[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)
                
            case false:
                do {
                    if self.selectedRowIndex > -1 {
                        if let oldCell = tableView.cellForRow(at: IndexPath.init(row: self.selectedRowIndex, section: 0)) as? ProfileListCell {
                            oldCell.isExpanded = false
                            self.selectedRowIndex = -1
                        }
                    }
                }
                
                self.expandedRows.removeAll()
                self.expandedRows.insert(post.id)
                
                if NotificationUtil.hasNewNotification {
                    self.markAllAsRead()
                }
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            self.tableView.beginUpdates()
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            self.expandedRows.remove(post.id)
            cell.isExpanded = false
            
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            if tableView == self.tableView {
                if let _user = UserController.Instance.getUser() as User? {
                    self.releasePlayer()
                    self.startIndicating()
                    
                    let _post = _user.getPosts(type: self.postType)[indexPath.row]
                    
                    PostService.Instance.deletePost(id: _post.id, completion: {
                        (success: Bool) in
                        self.stopIndicating()
                        
                        if success {
                            DispatchQueue.main.async {
                                let _ = UserController.Instance.deletePost(id: _post.id)
                                tableView.setEditing(false, animated: true)
                                self.tableView.reloadData()
                            }
                        } else {
                            AlertUtil.showSimpleAlert(self, title: "You have failed to delete the consult Please try again.", message: nil, okButtonTitle: "OK")
                        }
                    })
                    
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let _cell = cell as? ConsultCell,
            _cell.isExpanded == true {
            _cell.isExpanded = false
        }
        
    }
    
}

extension ProfileViewController : UIScrollViewDelegate {

    // MARK: UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            let offset: CGFloat = scrollView.contentOffset.y
            
            if offset >= 0 { // SCROLL UP/DOWN ------------
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

extension ProfileViewController {

    //MARK: IBActions
    
    @IBAction func onRecord(sender: AnyObject!) {
        vcDisappearType = .record
        self.releasePlayer()
        
        // Consult
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setPatient(patient: nil)
            DataManager.Instance.setFromPatientProfile(false)
            
            self.present(vc, animated: false, completion: nil)
            
        }
    }
    
}

extension ProfileViewController: ProfileListCellDelegate {
    
    func profileListCellDidTapReferringUser(_ user: User) {
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
