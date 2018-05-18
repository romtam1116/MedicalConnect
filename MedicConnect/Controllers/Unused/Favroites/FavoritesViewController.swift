//
//  FavoritesViewController.swift
//  MedicalConsult
//
//  Created by Roman on 11/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class FavoritesViewController: BaseViewController {
    
    let FollowingCellID = "FollowingCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    
    @IBOutlet var tvFavorites: UITableView!
    
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadData()
    }
    
    //MARK: UI Functions
    
    func initViews() {
        
        // Initialize Table Views
        let nib = UINib(nibName: FollowingCellID, bundle: nil)
        self.tvFavorites.register(nib, forCellReuseIdentifier: FollowingCellID)
        self.tvFavorites.tableFooterView = UIView()
        
    }
    
    // MARK: Private methods
    
    func loadData() {
        if (self.currentUser == nil) {
            UserService.Instance.getMe(completion: {
                (user: User?) in
                
                if let _ = user as User? {
                    self.tvFavorites.reloadData()
                }
            })
        }
        
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if let _currentUser = self.currentUser as User? {
            
            return _currentUser.following.count
            
        } else if let _me = UserController.Instance.getUser() as User? {
            
            return _me.following.count
            
        } else {
            
            return 0
            
        }
        
    }
    
    /**
     Returns user for specific UITableView and index.
     
     - Parameter inTableView: UITableView user belongs
     - Parameter times: Index from UITableView user belongs
     
     - Returns: User or nil, if not found.
     */
    func getUserForRow(inTableView: UITableView, row: Int) -> User? {
        
        if let _currentUser = self.currentUser as User? {
            
            if row < _currentUser.following.count {
                return _currentUser.following[row] as? User
            } else {
                return nil
            }
            
        } else if let _me = UserController.Instance.getUser() as User? {
            
            if row < _me.following.count {
                return _me.following[row] as? User
            } else {
                return nil
            }
            
        } else {
            return nil
        }
        
    }
    
    /**
      - Gets index and UITableView reference from button to identify correct user.
      - Sends *follow* request to server.
      - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
    */
    func setFollow(sender: TVButton) {
        
        sender.makeEnabled(enabled: false)
        
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.follow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    
                    // If in Following list, just set button state locally, as it's better for UX.
                    // Otherwise, reload data.
//                    let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
//                    cell.toggleFollowData()
                    sender.makeEnabled(enabled: true)
                    self.loadData()
                    
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
        
        sender.makeEnabled(enabled: false)
        
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.unfollow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    
                    // If in Following list, just set button state locally, as it's better for UX.
                    // Otherwise, reload data.
//                    let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
//                    cell.toggleFollowData()
                    sender.makeEnabled(enabled: true)
                    self.loadData()
                }
                
            })
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
    
}

extension FavoritesViewController : UITableViewDelegate, UITableViewDataSource {

    // MARK: UITableView DataSource Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(inTableView: tableView, section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FollowingCell = tableView.dequeueReusableCell(withIdentifier: FollowingCellID) as! FollowingCell
        
        // Set button actions
        cell.btnFavorite.index = indexPath.row
        cell.btnFavorite.refTableView = tableView
        cell.btnFavorite.addTarget(self, action: #selector(FavoritesViewController.setUnfollow(sender:)), for: .touchUpInside)
        cell.btnFavorite.makeEnabled(enabled: true)
        
        // Set cell data
        if let _followingUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
            cell.setFollowData(user: _followingUser)
        }
        
        return cell
        
    }
    
    // MARK: UITableView Delegate Methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let _followingUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
            self.callProfileVC(user: _followingUser)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 98.0
    }

}

extension FavoritesViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
}
