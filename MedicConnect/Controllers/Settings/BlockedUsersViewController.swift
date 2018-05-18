//
//  BlockedUsersViewController.swift
//  MedicalConsult
//
//  Created by Voltae Saito on 7/3/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class BlockedUsersViewController: BaseViewController {

    var blockedUsers = [User]()
    
    @IBOutlet weak var m_tblBlockedUsers: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_tblBlockedUsers.tableFooterView = UIView.init(frame: .zero)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UserService.Instance.getMe { (user) in
            if let user = user {
                
                self.blockedUsers = user.blocking as! [User]
                self.m_tblBlockedUsers.reloadData()
                
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - UI Actions
    @IBAction func btnUnblockClicked(_ sender: UIButton) {
        let row = sender.tag
        let user = blockedUsers[row]
        
        UserService.Instance.unblock(userId: user.id) { (success) in
            print("\nUnblock User: \(success)\n")
            self.blockedUsers.remove(at: row)
            self.m_tblBlockedUsers.reloadData()
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: false, completion: nil)
    }
}

extension BlockedUsersViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "blockedUsersCellId"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BlockedUserTableViewCell
        
        let user = blockedUsers[indexPath.row]
        cell.configureCell(user: user)
        cell.m_btnBlock.tag = indexPath.row
        
        return cell
    }
    
    
}
