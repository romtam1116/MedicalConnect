//
//  AnotherProfileViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation

class AnotherProfileViewController: BaseViewController {
    
    let OffsetHeaderStop: CGFloat = 190.0
    let ProfileListCellID = "ProfileListCell"
    let PrivateUserTableViewCellID = "PrivateUserTableViewCell"
    
    // Header
    @IBOutlet var headerLabel: UILabel!
    
    // Profile info
    @IBOutlet var viewProfileInfo: UIView!
    @IBOutlet var imgAvatar: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblLocation: UILabel!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var btnFavorites: UIButton!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var currentUser: User?
    var selectedPostId: String?
    var selectedDotsIndex = 0
    
    var profileType = 0 //0: normal, 1: private, 2: blocked
    var postType: String = Constants.PostTypeAll
    var expandedRows = Set<String>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.headerViewHeightConstraint.constant = OffsetHeaderStop
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Table Views
        self.tableView.register(UINib(nibName: ProfileListCellID, bundle: nil), forCellReuseIdentifier: ProfileListCellID)
        self.tableView.register(UINib(nibName: PrivateUserTableViewCellID, bundle: nil), forCellReuseIdentifier: PrivateUserTableViewCellID)
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1 ))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.initViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.releasePlayer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    
    // MARK: Private methods
    
    func initViews() {
        
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        self.refreshData()
        
    }
    
    func refreshData() {
        
        if let _currentUser = self.currentUser as User? {
            
            // Update UI with basic user info
            self.updateUI(user: _currentUser)
            
            // Fetch all user data (primarily we only had basic info)
            UserService.Instance.getUser(forId: _currentUser.id, completion: {
                (user: User?) in
                
                if let _updatedUser = user as User? {
                    
                    if _updatedUser.isprivate == true {
                        self.profileType = 1
                    }
                    
                    self.currentUser = _updatedUser
                    self.updateUI(user: self.currentUser!)
                    
                    if let _user = self.currentUser {
                        if _user.getPosts(type: self.postType).count > 0 && self.selectedPostId != nil {
                            if let _postIndex = _user.getPostIndex(id: self.selectedPostId!) {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                                    let indexPath = IndexPath.init(row: _postIndex, section: 0)
                                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                    self.tableView(self.tableView, didSelectRowAt: indexPath)
                                }
                            }
                        }
                    }
                    
                } else {
                    self.profileType = 2
                }
                
            })
        }
        
    }
    
    func updateUI(user: User) {
        
        // Customize Avatar
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgAvatar.af_setImage(withURL: imgURL)
        } else {
            self.imgAvatar.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                     text: user.getInitials(),
                                                                                     font: UIFont(name: "Avenir-Book", size: 44)!,
                                                                                     size: CGSize(width: 98, height: 98))
        }
        
        // Customize User Info
        self.lblUsername.text = "\(user.fullName)"
        self.lblLocation.text = user.location
        self.lblTitle.text = user.title
        
        if self.profileType == 0 {
            // Private
            self.tableView.estimatedRowHeight = 110.0
            self.tableView.rowHeight = UITableViewAutomaticDimension
        } else {
            // Non Private
            self.tableView.rowHeight = 150.0
        }
        
        self.tableView.reloadData()
        self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        
    }
    
    // MARK: Scroll Ralated
    
    func updateScroll(offset: CGFloat) {
        
        self.viewProfileInfo.alpha = max (0.0, (OffsetHeaderStop - offset) / OffsetHeaderStop)
        
        // ScrollViews Frame
        if (offset >= OffsetHeaderStop) {
            self.tableViewTopConstraint.constant = offset - OffsetHeaderStop + self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64.0
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
        
        if let _user = self.currentUser as User?,
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
    
    @objc func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }

        guard let _user = self.currentUser as User? else {
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
            
            guard let _user = self.currentUser as User? else {
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
        
        guard let _user = self.currentUser as User? else {
            return
        }
        
        let post = _user.getPosts(type: self.postType)[_index]
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
            
            guard let _user = self.currentUser as User? else {
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
            
            guard let _user = self.currentUser as User? else {
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
    
}

extension AnotherProfileViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            if let _user = self.currentUser {
                if profileType == 0 {
                    return _user.getPosts(type: self.postType).count
                } else {
                    return 1
                }
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
            if profileType > 0 {
                let cellPrivate = tableView.dequeueReusableCell(withIdentifier: PrivateUserTableViewCellID, for: indexPath)
                return cellPrivate
            }
            
            let cell: ProfileListCell = tableView.dequeueReusableCell(withIdentifier: ProfileListCellID, for: indexPath) as! ProfileListCell
            
            guard let _user = self.currentUser else {
                return cell
            }
            
            cell.delegate = self
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            cell.setData(post: post)
            
            cell.lblDescription.isUserInteractionEnabled = false
            
            cell.btnSynopsis.tag = indexPath.row
            if post.transcriptionUrl == "" {
                cell.btnSynopsis.removeTarget(self, action: #selector(AnotherProfileViewController.onSynopsis(sender:)), for: .touchUpInside)
            } else if cell.btnSynopsis.allTargets.count == 0 {
                cell.btnSynopsis.addTarget(self, action: #selector(AnotherProfileViewController.onSynopsis(sender:)), for: .touchUpInside)
            }
            
            cell.btnSpeaker.tag = indexPath.row
            if cell.btnSpeaker.allTargets.count == 0 {
                cell.btnSpeaker.addTarget(self, action: #selector(onSelectSpeaker(sender:)), for: .touchUpInside)
            }
            
            cell.btnPlay.tag = indexPath.row
            if cell.btnPlay.allTargets.count == 0 {
                cell.btnPlay.addTarget(self, action: #selector(AnotherProfileViewController.onPlayAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnBackward.tag = indexPath.row
            if cell.btnBackward.allTargets.count == 0 {
                cell.btnBackward.addTarget(self, action: #selector(AnotherProfileViewController.onBackwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnForward.tag = indexPath.row
            if cell.btnForward.allTargets.count == 0 {
                cell.btnForward.addTarget(self, action: #selector(AnotherProfileViewController.onForwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.playSlider.index = indexPath.row
            cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
            if cell.playSlider.allTargets.count == 0 {
                cell.playSlider.addTarget(self, action: #selector(AnotherProfileViewController.onSeekSlider(sender:)), for: .valueChanged)
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
            
            guard let _user = self.currentUser else {
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
                self.expandedRows.insert(post.id)
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = self.currentUser else {
                return
            }
            
            self.tableView.beginUpdates()
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            self.expandedRows.remove(post.id)
            cell.isExpanded = false
            
            self.tableView.endUpdates()
        }
        
    }
    
}

extension AnotherProfileViewController : UIScrollViewDelegate {

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

extension AnotherProfileViewController {
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onFavorites(sender: AnyObject!) {
        
        guard let _currentUser = self.currentUser as User? else {
            return
        }
        if sender.tag == 2 {
            return
        }
        
        self.btnFavorites.makeEnabled(enabled: false)
        if sender.tag == 0 {
            UserService.Instance.follow(userId: _currentUser.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        self.refreshData()
                    })
                } else {
                    self.btnFavorites.makeEnabled(enabled: true)
                }
            })
            
        } else {
            
            UserService.Instance.unfollow(userId: _currentUser.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        self.refreshData()
                    })
                } else {
                    self.btnFavorites.makeEnabled(enabled: true)
                }
            })
            
        }
        
    }
}

extension AnotherProfileViewController: ProfileListCellDelegate {
    
    func profileListCellDidTapReferringUser(_ user: User) {
        // Show referring user profile
        if let _currentUser = self.currentUser as User? {
            if _currentUser.id == user.id {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if  let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
                
                if let blockedby = _currentUser.blockedby as? [User] {
                    if blockedby.contains(where: { $0.id == user.id }) {
                        return
                    }
                }
                if let blocking = _currentUser.blocking as? [User] {
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
