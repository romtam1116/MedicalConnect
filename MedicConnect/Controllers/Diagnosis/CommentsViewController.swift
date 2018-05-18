//
//  CommentsViewController.swift
//  MedicalConsult
//
//  Created by Roman on 12/27/16.
//  Copyright © 2016 Loewen-Daniel. All rights reserved.
//

import UIKit
import SZTextView
import IQKeyboardManager

class CommentsViewController: BaseViewController {
    
    let CommentsListCellID = "CommentsListCell"
    
    @IBOutlet var commentTextView: SZTextView!
    @IBOutlet var tvComments: UITableView!
    
    @IBOutlet weak var lbcBottomMargin: NSLayoutConstraint!
    
    var currentPost : Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CommentController.Instance.setComments([])
        
        IQKeyboardManager.shared().isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadComments()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
        IQKeyboardManager.shared().isEnabled = true
        
    }
    
    //MARK: Initialize Views
    
    func initViews() {
        
        // Initialize Table Views
        self.tvComments.register(UINib(nibName: CommentsListCellID, bundle: nil), forCellReuseIdentifier: CommentsListCellID)
        self.tvComments.tableFooterView = UIView()
        self.tvComments.estimatedRowHeight = 77.0
        self.tvComments.rowHeight = UITableViewAutomaticDimension
        
        let appendFont: UIFont = UIFont(name: "Avenir-Oblique", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 12.0)
        let appendAttributes = [ NSAttributedStringKey.foregroundColor : UIColor.lightGray, NSAttributedStringKey.font : appendFont ]
        let appendString = NSMutableAttributedString(string: "Type your comment", attributes: appendAttributes)
        self.commentTextView.attributedPlaceholder = appendString
        
        var aCorrection = (self.commentTextView.bounds.size.height - self.commentTextView.contentSize.height * self.commentTextView.zoomScale) / 2.0
        aCorrection = max(0, aCorrection)
        self.commentTextView.contentInset = UIEdgeInsets(top: aCorrection, left: 10, bottom: 0, right: 0)
        
    }
    
    func loadComments() {
        guard let post = self.currentPost else {
            return
        }
        
        CommentService.Instance.getComments(post.id) { (success : Bool) in
            if (success) {
                self.tvComments.reloadData()
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var bottomMargin = keyboardSize.height
            if UIScreen.main.nativeBounds.height == 2436 {
                bottomMargin = bottomMargin - 34
            }
            
            lbcBottomMargin.constant = bottomMargin
            
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        lbcBottomMargin.constant = 0
        UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
            self.view.layoutIfNeeded()
        })
        
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

extension CommentsViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSend(_ sender: Any) {
        
        guard let comment = self.commentTextView.text, !comment.isEmpty else {
            return
        }
        
        guard let post = self.currentPost else {
            return
        }
        
        guard let _sender = sender as? UIButton else {
            return
        }
        
        guard let _user = UserController.Instance.getUser() else {
            return
        }
        
        let content = commentTextView.text!
        
        _sender.makeEnabled(enabled: false)
        CommentService.Instance.postComment(post.id, content: content) { (success: Bool, _comment: Comment?) in
            if (success) {
                var comments = CommentController.Instance.getComments()
                
                let _c = _comment!
                _c.url = _user.photo
                _c.author = _user.fullName
                _c.user = _user
                
                comments.append(_c)
                CommentController.Instance.setComments(comments)
                
                self.tvComments.reloadData()
            }
            
            _sender.makeEnabled(enabled: true)
            self.commentTextView.text = ""
            self.commentTextView.resignFirstResponder()
        }
        
    }
    
}

extension CommentsViewController : UITableViewDataSource, UITableViewDelegate{
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return CommentController.Instance.getComments().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvComments {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CommentsListCellID) as! CommentsListCell
            let comment = CommentController.Instance.getComments()[indexPath.row]
            
            cell.setCellWithAuthor(url: comment.url, author: comment.author, date: comment.getFormattedDate(), comment: comment.comment)
            
            return cell
        }
        
        return UITableViewCell()
        
    }
    
    //MARK: UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let comment = CommentController.Instance.getComments()[indexPath.row]
        self.callProfileVC(user: comment.user)
        
    }
    
}
