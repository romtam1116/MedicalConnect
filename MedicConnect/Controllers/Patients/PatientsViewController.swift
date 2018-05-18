//
//  PatientsViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-10-16.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import IQKeyboardManager

class PatientsViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    let PatientCellID = "PatientListCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tvPatients: UITableView!
    @IBOutlet var btnCreatePatient: UIButton!
    
    @IBOutlet var constOfTableViewBottom: NSLayoutConstraint!
    
    var menuButton: ExpandingMenuButton?
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var searchedPatients: [Patient] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureExpandingMenuButton()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vcDisappearType = .other
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.loadPatients()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear search field and results
        self.txFieldSearch.text = ""
        self.loadSearchResult(self.txFieldSearch.text!)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.initViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension PatientsViewController {
    
    // MARK: Private methods
    
    fileprivate func configureExpandingMenuButton() {
        self.btnCreatePatient.isHidden = true
        
        let tabBarHeight = UIScreen.main.nativeBounds.height == 2436 ? CGFloat(TABBAR_HEIGHT) + 26.0 : CGFloat(TABBAR_HEIGHT)
        let menuButtonSize: CGSize = CGSize(width: 58.0, height: 58.0)
        self.menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize), centerImage: UIImage(named: "icon_patient_add")!, centerHighlightedImage: UIImage(named: "icon_patient_add")!)
        menuButton!.center = CGPoint(x: self.view.bounds.width - 44.0, y: self.view.bounds.height - 34.0 - tabBarHeight)
        self.view.addSubview(menuButton!)
        
        let item1 = ExpandingMenuItem(size: CGSize(width: 50.0, height: 50.0), title: "Create New Patient File", image: UIImage(named: "icon_record_consult")!, highlightedImage: UIImage(named: "icon_record_consult")!, backgroundImage: nil, backgroundHighlightedImage: nil) { () -> Void in
            // Create Form
            self.performSegue(withIdentifier: Constants.SegueMedicConnectAddPatient, sender: nil)
        }
        
        let item2 = ExpandingMenuItem(size: CGSize(width: 50.0, height: 50.0), title: "Scan Patient Label", image: UIImage(named: "icon_scan_label")!, highlightedImage: UIImage(named: "icon_scan_label")!, backgroundImage: nil, backgroundHighlightedImage: nil) { () -> Void in
            // Scan
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if  let vc = storyboard.instantiateViewController(withIdentifier: "PatientScanViewController") as? PatientScanViewController {
                self.navigationController?.pushViewController(vc, animated: false)
            }
        }
        
        menuButton!.addMenuItems([item1, item2])
        
        menuButton!.willPresentMenuItems = { (menu) -> Void in
            self.menuButton!.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(self.menuButton!)
        }
        
        menuButton!.didDismissMenuItems = { (menu) -> Void in
            self.menuButton!.removeFromSuperview()
            self.view.addSubview(self.menuButton!)
        }
    }
    
    func initViews() {
        // Initialize Table Views
        
        let nibPatientCell = UINib(nibName: PatientCellID, bundle: nil)
        self.tvPatients.register(nibPatientCell, forCellReuseIdentifier: PatientCellID)
        
        self.tvPatients.tableFooterView = UIView()
        self.tvPatients.estimatedRowHeight = 95.0
        self.tvPatients.rowHeight = UITableViewAutomaticDimension
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            constOfTableViewBottom.constant = bottomMargin
            
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        constOfTableViewBottom.constant = 0
        
        UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func loadPatients() {
        // Load Patients
        
        PatientService.Instance.getPatients(completion: { (success: Bool) in
            self.loadSearchResult(self.txFieldSearch.text!)
        })
        
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchedPatients = []
        } else {
            searchedPatients = PatientController.Instance.getPatients().filter({(patient: Patient) -> Bool in
                return patient.patientNumber.contains(keyword) ||
                    patient.name.lowercased().contains(keyword.lowercased()) ||
                    patient.user.fullName.lowercased().contains(keyword.lowercased())
            })
        }
        
        self.tvPatients.reloadData()
    }
    
    // MARK: Selectors
    
    @objc func onSelectUser(sender: UITapGestureRecognizer) {
        let index = sender.view?.tag
        let patient: Patient? = self.searchedPatients[index!]
        
        if (patient != nil) {
            self.callProfileVC(user: (patient?.user)!)
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

extension PatientsViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.searchedPatients.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PatientListCell = tableView.dequeueReusableCell(withIdentifier: PatientCellID) as! PatientListCell
        let patient = self.searchedPatients[indexPath.row]
        
        cell.setData(patient)
        
        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.imgUserPhoto.addGestureRecognizer(tapGestureOnUserAvatar)
        cell.imgUserPhoto.tag = indexPath.row
        
        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.lblDoctorName.addGestureRecognizer(tapGestureOnUsername)
        cell.lblDoctorName.tag = indexPath.row
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let _patient = self.searchedPatients[indexPath.row] as Patient? else {
            return
        }
        
        let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
        patientProfileVC.patient = _patient
        patientProfileVC.fromAdd = false
        self.navigationController?.pushViewController(patientProfileVC, animated: true)

    }
    
}

extension PatientsViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
    @IBAction func onAddTapped(sender: AnyObject) {
        self.performSegue(withIdentifier: Constants.SegueMedicConnectAddPatient, sender: nil)
    }
    
}

extension PatientsViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        if (CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: txtAfterUpdate as String)) && txtAfterUpdate.length > Constants.MaxPHNLength) {
            return false
        }
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}
