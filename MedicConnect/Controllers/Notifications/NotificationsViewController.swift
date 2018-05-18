//
//  NotificationsViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/20/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class NotificationsViewController: BaseViewController {
    
    let NotificationListCellID = "NotificationListCell"
    
    @IBOutlet var tvNotifications: UITableView!
    
    var notificationsArr: [[String : AnyObject]] = []
    var needsReload: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadNotifications()
    }
    
    //MARK: UI Functions
    func initViews() {
        
        // Initialize Table Views
        self.tvNotifications.register(UINib(nibName: NotificationListCellID, bundle: nil), forCellReuseIdentifier: NotificationListCellID)
        self.tvNotifications.tableFooterView = UIView()
        self.tvNotifications.estimatedRowHeight = 70
        self.tvNotifications.rowHeight = UITableViewAutomaticDimension
        
    }
    
    func loadNotifications() {
        NotificationService.Instance.getNotifications { (success) in
            if (success) {
                self.refreshData()
                
                if NotificationController.Instance.getUnreadNotificationCount() > 0 {
                    self.needsReload = true
                    self.markAllAsRead()
                } else {
                    self.needsReload = false
                }
            }
        }
    }
    
    func markAllAsRead() {
        // Clear notification state
        UIApplication.shared.applicationIconBadgeNumber = 0
        NotificationUtil.updateNotificationAlert(hasNewAlert: false)
        
        NotificationService.Instance.markAllAsRead(completion: { (allRead) in
            if (allRead) {
                if self.needsReload {
                    NotificationController.Instance.markAllRead()
//                    self.refreshData()
                }
            }
        })
    }
    
    func callCommentVC(post: Post) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            vc.currentPost = post
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func callProfileVC(user: User, postId: String?) {
        
        if  let _me = UserController.Instance.getUser() as User? {
//            if _me.id == user.id {
//                return
//            }
            
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
                vc.selectedPostId = postId
                self.present(vc, animated: false, completion: nil)
                
            }
        }
        
    }
    
    func callTranscriptionVC(transcriptionUrl: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
            vc.strTitle = "Transcription"
            vc.strSynopsisUrl = transcriptionUrl
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
}

extension NotificationsViewController {

    //MARK: IBActions
    @IBAction func onBack(sender: AnyObject) {
        self.dismissVC()
    }

}

extension NotificationsViewController : UITableViewDelegate, UITableViewDataSource {
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tvNotifications {
            
            if NotificationController.Instance.getNotifications().count == 0 {
                
                let bgView: RadTableBackgroundView = RadTableBackgroundView(frame: tableView.bounds)
                bgView.setTitle("No Notifications.", caption: "No notifications to show...")
                tableView.backgroundView = bgView
                return 0
                
            } else {
                
                tableView.backgroundView = nil
                return 1
            }
        } else {
            
            return 1
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return NotificationController.Instance.getNotifications().count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvNotifications {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NotificationListCellID) as! NotificationListCell
            
            cell.setNotificationData(notification: NotificationController.Instance.getNotifications()[indexPath.row])
            
            cell.btnFollowing.isHidden = true
//            cell.btnFollowing.index = indexPath.row
//            cell.btnFollowing.refTableView = tableView
//            cell.btnFollowing.addTarget(self, action: #selector(NotificationsViewController.setUnfollow(sender:)), for: .touchUpInside)
//            cell.btnFollowing.makeEnabled(enabled: true)
            
            cell.btnUnFollow.isHidden = true
//            cell.btnUnFollow.index = indexPath.row
//            cell.btnUnFollow.refTableView = tableView
//            cell.btnUnFollow.addTarget(self, action: #selector(NotificationsViewController.setFollow(sender:)), for: .touchUpInside)
//            cell.btnUnFollow.makeEnabled(enabled: true)
            
            cell.btnAccept.isHidden = true
//            cell.btnAccept.index = indexPath.row
//            cell.btnAccept.addTarget(self, action: #selector(acceptRequest(sender:)),for: .touchUpInside)
//            cell.btnFollowing.makeEnabled(enabled: true)
            
            cell.btnDecline.isHidden = true
//            cell.btnDecline.index = indexPath.row
//            cell.btnDecline.addTarget(self, action: #selector(declineRequest(sender:)),for: .touchUpInside)
//            cell.btnUnFollow.makeEnabled(enabled: true)
            
            cell.btnRequested.isHidden = true
            
            return cell
            
        } else {
            
            return UITableViewCell()
            
        }
    }
    /**
     - Gets index and UITableView reference from button to identify correct user.
     - Sends *follow* request to server.
     - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
     */
    @objc func setFollow(sender: TVButton) {
        
        self.view.endEditing(true)
        
        sender.makeEnabled(enabled: false)
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.follow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    self.refreshData()
                } else {
                    sender.makeEnabled(enabled: true)
                }
                
            })
            
        }
    }
    
    /**
     - Gets index and UITableView reference from button to identify correct user.
     - Sends *unfollow* request to server.
     - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
     */
    @objc func setUnfollow(sender: TVButton) {
        
        self.view.endEditing(true)
        
        sender.makeEnabled(enabled: false)
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.unfollow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    self.refreshData()
                } else {
                    sender.makeEnabled(enabled: true)
                }
                
            })
        }
        
    }
    
    /**
     Returns user for specific UITableView and index.
     
     - Parameter inTableView: UITableView user belongs
     - Parameter times: Index from UITableView user belongs
     
     - Returns: User or nil, if not found.
     */
    func getUserForRow(inTableView: UITableView, row: Int) -> User? {
        
        if row >= NotificationController.Instance.getNotifications().count {
            return nil
        }
        
        if let _user = NotificationController.Instance.getNotifications()[row].fromUser as User? {
            return _user
        } else {
            return nil
        }
        
    }
    
    func refreshData() {
        
//        UserService.Instance.getMe(completion: {
//            (user: User?) in
//
//            if let _ = user as User? {
                self.tvNotifications.reloadData()
//            }
//        })
        
    }
    
    @objc func acceptRequest(sender: TVButton) {
        sender.makeEnabled(enabled: false)
        
        let row = sender.index
        let noti = NotificationController.Instance.getNotifications()[row!]
        UserService.Instance.acceptRequest(userId: noti.fromUser.id) { (success) in
            print("\nAccept Request: \(success)\n")
            if success {
                self.refreshData()
            } else {
                sender.makeEnabled(enabled: true)
            }
        }
        
    }
    
    @objc func declineRequest(sender: TVButton) {
        sender.makeEnabled(enabled: false)
        
        let row = sender.index
        let noti = NotificationController.Instance.getNotifications()[row!]
        UserService.Instance.declineRequest(userId: noti.fromUser.id) { (success) in
            print("\nDecline Request: \(success)\n")
            if success {
                self.refreshData()
            } else {
                sender.makeEnabled(enabled: true)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let notification = NotificationController.Instance.getNotifications()[indexPath.row]
        
        if notification.notificationType == .broadcast {
            callProfileVC(user: notification.fromUser, postId: notification.broadcast?.id)
        } else if notification.notificationType == .transcribed {
            if let _transcriptionURL = notification.broadcast?.transcriptionUrl {
                callTranscriptionVC(transcriptionUrl: _transcriptionURL)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    
}
