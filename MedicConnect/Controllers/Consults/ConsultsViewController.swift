//
//  ConsultsViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-11-16.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation
import Crashlytics

class ConsultsViewController: BaseViewController, UIGestureRecognizerDelegate {

    let ConsultCellID = "ConsultCell"
    let postType = Constants.PostTypeConsult
    let OffsetHeaderStop: CGFloat = 50
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tvConsults: UITableView!
    
    // Search
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var expandedRows = Set<String>()
    var selectedRowIndex = -1
    var searchResult: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadMe()
        self.markAllAsRead()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(ConsultsViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.selectedRowIndex = (self.tvConsults.indexPathForSelectedRow != nil) ? self.tvConsults.indexPathForSelectedRow!.row : -1
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if (vcDisappearType == .other) {
            self.releasePlayer()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        }
        
        
    }
    
    // MARK: Keyboard Functions
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            self.tableViewHeightConstraint.constant = self.tableViewHeightConstraint.constant - bottomMargin
            
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            self.tableViewHeightConstraint.constant = self.tableViewHeightConstraint.constant + bottomMargin
        
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Private Functions
    
    func initViews() {
        
        // Initialize Table Views
        let nibConsultCell = UINib(nibName: ConsultCellID, bundle: nil)
        self.tvConsults.register(nibConsultCell, forCellReuseIdentifier: ConsultCellID)
        
        self.tvConsults.tableFooterView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.tvConsults.frame.size.width, height: 20.0))
        self.tvConsults.estimatedRowHeight = 100.0
        self.tvConsults.rowHeight = UITableViewAutomaticDimension
        
        // Hide search bar in the beginning
        self.mainScrollView.contentOffset = CGPoint.init(x: 0, y: OffsetHeaderStop)
        
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
    
}

extension ConsultsViewController {
    
    // MARK: Private methods
    
    func loadMe() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _user = user as User? {
                self.logUser(user: _user)
                self.loadPosts()
            }
        })
        
    }
    
    func loadPosts() {
        
        // Load Timeline
        UserService.Instance.getTimeline(self.postType, completion: {
            (success: Bool) in
            if success {
                self.selectedRowIndex = (self.tvConsults.indexPathForSelectedRow != nil) ? self.tvConsults.indexPathForSelectedRow!.row : -1
                self.loadSearchResult(self.txFieldSearch.text!)
                self.updateScroll(offset: self.mainScrollView.contentOffset.y)
            }
        })
        
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchResult = PostController.Instance.getFollowingPosts(type: self.postType)
        } else {
            searchResult = PostController.Instance.getFollowingPosts(type: self.postType).filter({(post: Post) -> Bool in
                return post.patientName.lowercased().contains(keyword.lowercased()) ||
                    post.patientPHN.contains(keyword) ||
                    post.descriptions.lowercased().contains(keyword.lowercased()) ||
                    post.user.fullName.lowercased().contains(keyword.lowercased())
            })
        }
        
        self.tvConsults.reloadData()
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
            let post = searchResult[_index]
            post.setPlayed(time: kCMTimeZero, progress: 0.0, setLastPlayed: false)
            
            let cell = self.tvConsults.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ConsultCell
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
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            _lastPlayed.playing == true {
            self.onPauseAudio(sender: sender)
            return
        }
        
        let post = searchResult[_index]
        
        if let _url = URL(string: post.audio ) as URL? {
            let cell = self.tvConsults.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ConsultCell
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
            
            let post = searchResult[_index]
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
        
        let post = searchResult[_index]
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
            vc.strTitle = "Transcription"
            vc.strSynopsisUrl = post.transcriptionUrl
            present(vc, animated: true, completion: nil)
            
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
            
            let post = searchResult[_index]
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
            
            let post = searchResult[_index]
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
    
    // MARK: Selectors
    
    @objc func onSelectUser(sender: UITapGestureRecognizer) {
        let index = sender.view?.tag
        let post : Post? = searchResult[index!]
        
        if (post != nil) {
            self.callProfileVC(user: (post?.user)!)
        }
    }
    
    @objc func onSelectHashtag(sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView //sender is TextView
        let _pos: CGPoint = sender.location(in: myTextView)
        
        // eliminate scroll offset
//        pos.y += _tv.contentOffset.y;
        
        // get location in text from textposition at point
        let tapPos = myTextView.closestPosition(to: _pos)
        
        // fetch the word at this position (or nil, if not available)
        if let wordRange = myTextView.tokenizer.rangeEnclosingPosition(tapPos!, with: UITextGranularity.word, inDirection: UITextLayoutDirection.right.rawValue),
            let tappedHashtag = myTextView.text(in: wordRange) {
            NSLog("Word: \(String(describing: tappedHashtag))")
            self.callSearchResultVC(hashtag: tappedHashtag)
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
    
    func callProfileVC(user: User) {
        
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
    
    func callSearchResultVC(hashtag: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "SearchResultsViewController") as? SearchResultsViewController {
            vc.hashtag = hashtag
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    func logUser(user : User) {
        // TODO: Use the current user's information
        // You can call any combination of these three methods
        Crashlytics.sharedInstance().setUserEmail(user.email)
        Crashlytics.sharedInstance().setUserIdentifier(user.id)
        Crashlytics.sharedInstance().setUserName(user.fullName)
    }
    
    // MARK: Scroll Ralated
    
    func updateScroll(offset: CGFloat) {
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
        
        let scrollView: UIScrollView = self.tvConsults
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.width, height: max(self.view.frame.height - 64.0 + OffsetHeaderStop, scrollView.contentSize.height + self.headerViewHeightConstraint.constant))
        return scrollView
        
    }
    
}

extension ConsultsViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ConsultCell = tableView.dequeueReusableCell(withIdentifier: ConsultCellID) as! ConsultCell
        
        cell.delegate = self
        
        let post = searchResult[indexPath.row]
        cell.setData(post: post)
        
        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.imgUserAvatar.addGestureRecognizer(tapGestureOnUserAvatar)
        cell.imgUserAvatar.tag = indexPath.row
        
        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.lblUsername.addGestureRecognizer(tapGestureOnUsername)
        cell.lblUsername.tag = indexPath.row
        
        cell.lblDescription.isUserInteractionEnabled = false
        
        cell.btnSynopsis.tag = indexPath.row
        if post.transcriptionUrl == "" {
            cell.btnSynopsis.removeTarget(self, action: #selector(onSynopsis(sender:)), for: .touchUpInside)
        } else if cell.btnSynopsis.allTargets.count == 0 {
            cell.btnSynopsis.addTarget(self, action: #selector(onSynopsis(sender:)), for: .touchUpInside)
        }
        
        cell.txtVHashtags.isUserInteractionEnabled = false
//        let tapGestureOnHashtags = UITapGestureRecognizer(target: self, action: #selector(onSelectHashtag(sender:)))
//        cell.txtVHashtags.addGestureRecognizer(tapGestureOnHashtags)
//        cell.txtVHashtags.tag = indexPath.row
        
        cell.btnSpeaker.tag = indexPath.row
        if cell.btnSpeaker.allTargets.count == 0 {
            cell.btnSpeaker.addTarget(self, action: #selector(onSelectSpeaker(sender:)), for: .touchUpInside)
        }
        
        cell.btnPlay.tag = indexPath.row
        if cell.btnPlay.allTargets.count == 0 {
            cell.btnPlay.addTarget(self, action: #selector(onPlayAudio(sender:)), for: .touchUpInside)
        }
        
        cell.btnBackward.tag = indexPath.row
        if cell.btnBackward.allTargets.count == 0 {
            cell.btnBackward.addTarget(self, action: #selector(onBackwardAudio(sender:)), for: .touchUpInside)
        }
        
        cell.btnForward.tag = indexPath.row
        if cell.btnForward.allTargets.count == 0 {
            cell.btnForward.addTarget(self, action: #selector(onForwardAudio(sender:)), for: .touchUpInside)
        }
        
        cell.playSlider.index = indexPath.row
        cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
        if cell.playSlider.allTargets.count == 0 {
            cell.playSlider.addTarget(self, action: #selector(onSeekSlider(sender:)), for: .valueChanged)
        }
        
        cell.isExpanded = self.expandedRows.contains(post.id)
        cell.selectionStyle = .none
        
        return cell
        
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConsultCell
            else { return }
        
        self.releasePlayer()
        
        if PlayerController.Instance.lastPlayed == nil {
            cell.playSlider.setValue(0.0, animated: false)
            cell.playSlider.playing = false
        }
        
        self.tvConsults.beginUpdates()
        
        let post = searchResult[indexPath.row]
        
        switch cell.isExpanded {
        case true:
            self.expandedRows.remove(post.id)
            
        case false:
            do {
                if self.selectedRowIndex > -1 {
                    if let oldCell = tableView.cellForRow(at: IndexPath.init(row: self.selectedRowIndex, section: 0)) as? ConsultCell {
                        oldCell.isExpanded = false
                        self.selectedRowIndex = -1
                    }
                }
                
                self.expandedRows.removeAll()
                self.expandedRows.insert(post.id)
            }
        }
        
        cell.isExpanded = !cell.isExpanded
        
        self.tvConsults.endUpdates()
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConsultCell
            else { return }
        
        self.tvConsults.beginUpdates()
        
        let post = searchResult[indexPath.row]
        self.expandedRows.remove(post.id)
        cell.isExpanded = false
        
        self.tvConsults.endUpdates()
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let _cell = cell as? ConsultCell,
            _cell.isExpanded == true {
            _cell.isExpanded = false
        }
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return searchResult.count
    }

}

extension ConsultsViewController : UIScrollViewDelegate {
    
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
            self.tvConsults.setContentOffset(CGPoint.zero, animated: true)
        }
        
    }
    
}

extension ConsultsViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }

}

extension ConsultsViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}

extension ConsultsViewController: ConsultCellDelegate {
    
    func consultCellDidTapReferringUser(_ user: User) {
        // Show referring user profile
        self.callProfileVC(user: user)
    }
    
}
