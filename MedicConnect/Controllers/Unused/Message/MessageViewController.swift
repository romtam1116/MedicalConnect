//
//  MessageViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-10-11.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

class MessageViewController: BaseViewController {

    @IBOutlet weak var tvMessage: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tvMessage.tableFooterView = UIView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
