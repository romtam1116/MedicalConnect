//
//  SearchViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/29/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit

class SearchViewController: BaseViewController {
    
    let SearchPeopleCellID = "FollowingCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tableView: UITableView!
    
    // data
    var userArr: [User] = []
    var searchTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
        // Clear search field
        self.txFieldSearch.text = ""
        self.view.endEditing(true)
    }
    
    //MARK: Private methods
    
    func initViews() {
        // Initialize views
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: SearchPeopleCellID, bundle: nil), forCellReuseIdentifier: SearchPeopleCellID)
        self.tableView.tableFooterView = UIView.init(frame: .zero)
        
        self.txFieldSearch.delegate = self
        
    }
    
    func loadData() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _ = user as User? {
                self.loadSearchTab(self.txFieldSearch.text!)
            }
        })
        
    }
    
    func loadSearchTab(_ keyword: String) {
        // Local search
        self.userArr = UserController.Instance.searchForUsers(string: keyword)
        self.tableView.reloadData()
    }
    
    /**
     Returns user for specific UITableView and index.
     
     - Parameter inTableView: UITableView user belongs
     - Parameter times: Index from UITableView user belongs
     
     - Returns: User or nil, if not found.
     */
    func getUserForRow(inTableView: UITableView, row: Int) -> User? {
        
        if row >= self.userArr.count {
            return nil
        }
        
        if let _user = self.userArr[row] as User?, inTableView == self.tableView {
            return _user
        } else {
            return nil
        }
        
    }
    
    //MARK: Functions
    
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
    
    func onFavorites(sender: TVButton) {
        
        sender.makeEnabled(enabled: false)
        
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            if sender.tag == 1 {
                UserService.Instance.unfollow(userId: _user.id, completion: {
                    (success: Bool) in
                    
                    if success {
                        // If in Following list, just set button state locally, as it's better for UX.
                        // Otherwise, reload data.
                        if _tableView == self.tableView {
                            let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
                            
                            cell.btnFavorite.setImage(UIImage(named: "icon_favorites_off"), for: .normal)
                            cell.btnFavorite.tag = 0
                            
                            sender.makeEnabled(enabled: true)
                        }
                        
                        self.loadData()
                    }
                    
                })
                
            } else {
                UserService.Instance.follow(userId: _user.id, completion: {
                    (success: Bool) in
                    
                    if success {
                        // If in Following list, just set button state locally, as it's better for UX.
                        // Otherwise, reload data.
                        if _tableView == self.tableView {
                            let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
                            
                            cell.btnFavorite.setImage(UIImage(named: "icon_favorites"), for: .normal)
                            cell.btnFavorite.tag = 1
                            
                            sender.makeEnabled(enabled: true)
                        }
                        
                        self.loadData()
                    }
                    
                })
            }
        }
        
    }
    
}

extension SearchViewController : UITableViewDelegate, UITableViewDataSource {
    
    // Mark: UITableView delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userArr.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let _user = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
            self.callProfileVC(user: _user)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchPeopleCellID) as! FollowingCell
        
        // Set button actions
//        cell.btnFavorite.index = indexPath.row
//        cell.btnFavorite.refTableView = tableView
//        cell.btnFavorite.addTarget(self, action: #selector(SearchViewController.onFavorites(sender:)), for: .touchUpInside)
//        cell.btnFavorite.makeEnabled(enabled: true)
        cell.btnFavorite.isHidden = true
        cell.btnAction.isHidden = true
        
        // Set cell data
        if let user = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
//            if let _user = UserController.Instance.getUser() as User? {
//                let hasFollowed = (_user.following as! [User]).contains(where: { $0.id == user.id })
//                let image = hasFollowed ? UIImage(named: "icon_favorites") : UIImage(named: "icon_favorites_off")
//                cell.btnFavorite.setImage(image, for: .normal)
//                cell.btnFavorite.tag = hasFollowed ? 1 : 0
//            }
            
            cell.setFollowData(user: user)
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 98.0
    }
    
}

extension SearchViewController {
    
    // Mark: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
}

extension SearchViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        // Remote search
//        if txtAfterUpdate.length > 0 {
//            self.searchTimer?.invalidate()
//            self.searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SearchViewController.loadData(searchTimer:)), userInfo: txtAfterUpdate as String, repeats: false)
//        }
        
        self.loadSearchTab(txtAfterUpdate as String)
        
        return true
        
    }
    
}
