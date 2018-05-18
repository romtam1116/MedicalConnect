//
//  LikesViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-09.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class LikesViewController: BaseViewController {
    
    let LikesListCellID = "FollowingCell"
    
    @IBOutlet var tvLikes: UITableView!
    
    var currentPost : Post?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LikeController.Instance.setPostLikes([])

        initViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadLikes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //MARK: Initialize Views
    
    func initViews() {
        
        // Initialize Table View
        self.tvLikes.register(UINib(nibName: LikesListCellID, bundle: nil), forCellReuseIdentifier: LikesListCellID)
        self.tvLikes.tableFooterView = UIView()
        
    }
    
    //MARK: Functions
    
    func loadLikes() {
        guard let post = self.currentPost else {
            return
        }
        
        PostService.Instance.getPostLikes(post.id) { (success : Bool) in
            if (success) {
                self.tvLikes.reloadData()
            }
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
    
    /**
     - Gets index and UITableView reference from button to identify correct user.
     - Sends *follow* request to server.
     - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
     */
    func setFollow(sender: TVButton) {
        
        self.view.endEditing(true)
        
        sender.makeEnabled(enabled: false)
        if let _index = sender.index as Int?,
            let _user = LikeController.Instance.getPostLikes()[_index] as User? {
            
            UserService.Instance.follow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        
                        if let _ = user as User? {
                            self.tvLikes.reloadData()
                        }
                    })
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
    func setUnfollow(sender: TVButton) {
        
        self.view.endEditing(true)
        
        sender.makeEnabled(enabled: false)
        if let _index = sender.index as Int?,
            let _user = LikeController.Instance.getPostLikes()[_index] as User? {
            
            UserService.Instance.unfollow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        
                        if let _ = user as User? {
                            self.tvLikes.reloadData()
                        }
                    })
                } else {
                    sender.makeEnabled(enabled: true)
                }
                
            })
        }
        
    }

}

extension LikesViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}

extension LikesViewController : UITableViewDataSource, UITableViewDelegate{
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LikeController.Instance.getPostLikes().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvLikes {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: LikesListCellID) as! FollowingCell
            
            // Set button actions
            
//            cell.btnFollowing.index = indexPath.row
//            cell.btnFollowing.refTableView = tableView
//            cell.btnFollowing.addTarget(self, action: #selector(LikesViewController.setUnfollow(sender:)), for: .touchUpInside)
//            cell.btnFollowing.makeEnabled(enabled: true)
//            
//            cell.btnUnFollow.index = indexPath.row
//            cell.btnUnFollow.refTableView = tableView
//            cell.btnUnFollow.addTarget(self, action: #selector(LikesViewController.setFollow(sender:)), for: .touchUpInside)
//            cell.btnUnFollow.makeEnabled(enabled: true)
            
            // Set cell data
            if let _user = LikeController.Instance.getPostLikes()[indexPath.row] as User? {
                cell.setFollowData(user: _user)
            }
            
            //TODO: create a method to reset cell if user wasn't found. apply to other app cells as well.
            
            return cell
        }
        
        return UITableViewCell()
        
    }
    
    //MARK: UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let _user = LikeController.Instance.getPostLikes()[indexPath.row] as User? {
            self.callProfileVC(user: _user)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
}
