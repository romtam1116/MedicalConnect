//
//  TutorialViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2017-08-13.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit

enum TutorialType {
    case home
    case profile
}

class TutorialViewController: BaseViewController {

    @IBOutlet weak var ivBackground: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    fileprivate var tutorialImages: [String] = []
    
    // Home/Profile
    var type:TutorialType = .home {
        didSet {
            if type == .home {
                self.tutorialImages = ["home_tutorial1", "home_tutorial2", "home_tutorial3" ,"home_tutorial4"]
            } else if type == .profile {
                self.tutorialImages = ["profile_tutorial1", "profile_tutorial2", "profile_tutorial3" ,"profile_tutorial4", "profile_tutorial5"]
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupUI()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private Functions
    
    private func setupUI() {
        // Set up UI controls
        if let imageName = self.tutorialImages[0] as String? {
            self.ivBackground.image = UIImage.init(named: imageName)
            self.ivBackground.tag = 0
            self.ivBackground.isUserInteractionEnabled = true
            
            let tapGestureOnImage = UITapGestureRecognizer(target: self, action: #selector(onTapImage(sender:)))
            self.ivBackground.addGestureRecognizer(tapGestureOnImage)
            
            self.pageControl.numberOfPages = self.tutorialImages.count
        }
        
        self.pageControl.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        self.pageControl.currentPage = 0
        
    }
    
    // MARK: - IBActions
    
    @IBAction func onCloseBtnClicked(_ sender: Any) {
        self.dismissVC()
    }

    // MARK: - Tap Gesture
    @objc func onTapImage(sender: UITapGestureRecognizer) {
        // Image Tapped, Show next tutorial image
        if self.ivBackground.tag < self.tutorialImages.count - 1 {
            let nextIndex = self.ivBackground.tag + 1
            
            self.ivBackground.image = UIImage.init(named: self.tutorialImages[nextIndex])
            self.ivBackground.tag = nextIndex
            self.pageControl.currentPage = nextIndex
        }
        
    }

}
