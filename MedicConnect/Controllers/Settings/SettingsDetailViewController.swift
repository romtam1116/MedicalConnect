//
//  SettingsDetailViewController.swift
//  MedicalConsult
//
//  Created by Voltae Saito on 7/1/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import UIKit
import MessageUI
import MobileCoreServices
import PDFKit

class SettingsDetailViewController: BaseViewController {

    var strTitle: String?
    var strSynopsisUrl: String?
    var destinationFileUrl: URL!
    
    let contentDict = ["Privacy Policy":"Privacy_policy_HTML", "Code of Conduct": "Code_of_conduct_HTML", "Terms of Use": "Terms_of_service_HTML"]
    
    private var _pdfDocument: Any?
    @available(iOS 11.0, *)
    fileprivate var pdfDocument: PDFDocument? {
        get {
            return _pdfDocument as? PDFDocument
        }
        set {
            _pdfDocument = newValue
        }
    }
    
    private var _pdfView: Any?
    @available(iOS 11.0, *)
    fileprivate var pdfView: PDFView! {
        get {
            return _pdfView as! PDFView
        }
        set {
            _pdfView = newValue
        }
    }
    
    @IBOutlet weak var m_lblTitle: UILabel!
    @IBOutlet weak var m_btnEdit: UIButton!
    @IBOutlet weak var m_btnShare: UIButton!
    @IBOutlet weak var m_contentWebView: UIWebView!
    @IBOutlet weak var m_pdfView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide Save button
        self.m_btnEdit.isHidden = true
        self.m_btnShare.isHidden = true
        
        openContents()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // Mark : Private Methods
    
    func openContents() {
        if let titleText = strTitle {
            self.m_lblTitle.text = titleText
            
            if let synopsisUrl = self.strSynopsisUrl as String? {
                self.downloadPDF(fileURL: URL(string: synopsisUrl)!)
                
            } else if let contentPath = contentDict[titleText] {
                self.m_pdfView.isHidden = true
                
                let url = Bundle.main.url(forResource: contentPath, withExtension: "html")
                let request = URLRequest(url: url!)
                self.m_contentWebView.loadRequest(request)
            }
        }
    }
    
    func downloadPDF(fileURL: URL) {
        // Create destination URL
        let documentsUrl: URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.destinationFileUrl = documentsUrl.appendingPathComponent("Synopsis.pdf") as URL?
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                
                do {
                    if FileManager.default.fileExists(atPath: self.destinationFileUrl.path) {
                        try FileManager.default.removeItem(at: self.destinationFileUrl)
                    }
                    
                    try FileManager.default.copyItem(at: tempLocalUrl, to: self.destinationFileUrl)
                    
                    DispatchQueue.main.async {
                        // Show PDF
                        if #available(iOS 11.0, *) {
                            self.m_contentWebView.isHidden = true
                            self.m_btnEdit.isHidden = false
                            self.m_btnShare.isHidden = false
                            
                            self.pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: self.m_pdfView.frame.width, height: self.m_pdfView.frame.height))
                            self.pdfDocument = PDFDocument(url: self.destinationFileUrl!)
                            
                            self.pdfView.document = self.pdfDocument
                            self.pdfView.displayMode = PDFDisplayMode.singlePageContinuous
                            self.pdfView.autoScales = true
                            self.pdfView.backgroundColor = UIColor.lightGray
                            
                            self.m_pdfView.addSubview(self.pdfView)
                        } else {
                            // Fallback on earlier versions
                            self.m_pdfView.isHidden = true
                            
                            let request = URLRequest(url: self.destinationFileUrl)
                            self.m_contentWebView.loadRequest(request)
                        }
                    }
                    
                } catch (let writeError) {
                    print("Error creating a file \(self.destinationFileUrl) : \(writeError)")
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
    }
    
    // Mark : UI Actions
    @IBAction func btnBackClicked(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func btnEditClicked(_ sender: Any) {
        
//        if #available(iOS 11.0, *) {
//            if let page = self.pdfDocument?.page(at: 0) {
//                let upperSelection = self.pdfDocument?.findString("Consult Notes:", withOptions: .literal)[0]
//                let bottomSelection = self.pdfDocument?.findString("Consult Prepared by:", withOptions: .literal)[0]
//                let upperBounds = upperSelection?.bounds(for: page)
//                let bottomBounds = bottomSelection?.bounds(for: page)
//                let pageBounds = page.bounds(for: .cropBox)
//
//                let textFieldMultilineBounds = CGRect(x: (bottomBounds?.origin.x)!, y: (bottomBounds?.origin.y)! + 22, width: (pageBounds.size.width - (bottomBounds?.origin.x)! * 2), height: ((upperBounds?.origin.y)! - (bottomBounds?.origin.y)! - 35))
//                let textFieldMultiline = PDFAnnotation(bounds: textFieldMultilineBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
//                textFieldMultiline.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
//                textFieldMultiline.backgroundColor = UIColor.white
//                textFieldMultiline.font = UIFont.systemFont(ofSize: 12)
//                textFieldMultiline.isMultiline = true
//                textFieldMultiline.shouldDisplay = true
//                textFieldMultiline.setValue("Test. Test.", forAnnotationKey: .widgetValue)
//
//                let border = PDFBorder()
//                border.lineWidth = 1.0
//                textFieldMultiline.border = border
//
//                page.addAnnotation(textFieldMultiline)
//
////                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
////                    let gestures = self.pdfView.gestureRecognizers
////                    let allTextViews: [UITextView] = self.getSubviewsOf(view: self.pdfView)
////                    print(allTextViews)
////                }
//            }
//        } else {
//            // Fallback on earlier versions
//
//        }
        
    }
    
    private func getSubviewsOf<T: UIView>(view: UIView) -> [T] {
        var subviews = [T]()
        
        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]
            
            if let subview = subview as? T {
                subviews.append(subview)
            }
        }
        
        return subviews
    }

    @IBAction func btnShareClicked(_ sender: UIButton) {
        // Present AlertController
        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        let printAction = UIAlertAction.init(title: "PRINT", style: .default) { (action) in
            // Print
            if UIPrintInteractionController.canPrint(self.destinationFileUrl) {
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = self.destinationFileUrl.lastPathComponent
                printInfo.outputType = .general
                
                let printController = UIPrintInteractionController.shared
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = true
                printController.printingItem = self.destinationFileUrl
                
                printController.present(animated: true)
            } else {
                AlertUtil.showSimpleAlert(self, title: "Print service is not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        printAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        printAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        printAction.setValue(UIImage(named:"icon_print")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(printAction)

        let submitMSPAction = UIAlertAction.init(title: "EMAIL", style: .default) { (action) in
            // Email
            if( MFMailComposeViewController.canSendMail()){
                print("Can send email.")
                
                DispatchQueue.main.async {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.mailComposeDelegate = self
                    
//                    mailComposer.setToRecipients(["yakupad@yandex.com"])
//                    mailComposer.setSubject("email with document pdf")
//                    mailComposer.setMessageBody("This is what they sound like.", isHTML: true)
                    
                    let pathPDF = self.destinationFileUrl.path
                    if let fileData = NSData(contentsOfFile: pathPDF) {
                        mailComposer.addAttachmentData(fileData as Data, mimeType: "application/pdf", fileName: self.destinationFileUrl.lastPathComponent)
                    }
                    
                    //this will compose and present mail to user
                    self.present(mailComposer, animated: true, completion: nil)
                }
            } else {
                print("email is not supported")
                AlertUtil.showSimpleAlert(self, title: "Mail services are not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        submitMSPAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        submitMSPAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        submitMSPAction.setValue(UIImage(named:"icon_submit")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(submitMSPAction)

        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel)
        cancelAction.setValue(UIColor.init(red: 143/255.0, green: 195/255.0, blue: 196/255.0, alpha: 1), forKey: "titleTextColor")
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        // Update AlertController Style
        
        let attributedText = NSMutableAttributedString(string: "SUBMIT TO MSP")
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.font, value: UIFont(name: "Avenir-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15), range: range)
        
        let actionViews = alertController.view.value(forKey: "actionViews") as! [UIView]
        if actionViews.count > 0 {
            let printView = actionViews[0] as UIView
//            (printView.value(forKey: "label") as! UILabel).attributedText = attributedText
            (printView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 84
            
            let submitMSPView = actionViews[1] as UIView
//            (submitMSPView.value(forKey: "label") as! UILabel).font = UIFont(name: "Avenir-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15)
            (submitMSPView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 80
        }
        
    }
    
}

extension SettingsDetailViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url?.absoluteString {
            if url == "https://www.codiapp.com/privacy" {
                self.strTitle = "Privacy Policy"
                openContents()
            } else if url == "https://www.codiapp.com/conduct" {
                self.strTitle = "Code of Conduct"
                openContents()
            } else if url == "https://www.codiapp.com/support" {
                self.sendEmail(subject: "Contact Us", msgbody: "")
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if (self.strSynopsisUrl as String?) != nil {
            // Synopsis Document
//            self.m_btnEdit.isHidden = false
            self.m_btnShare.isHidden = false
            
            // Enable zoom
            self.m_contentWebView.scrollView.minimumZoomScale = 1.0
            self.m_contentWebView.scrollView.maximumZoomScale = 5.0
        }
    }
}


extension SettingsDetailViewController : MFMailComposeViewControllerDelegate {
    func sendEmail(subject: String, msgbody: String){
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["info@codiapp.com"])
        mailComposer.setSubject( subject )
        mailComposer.setMessageBody(msgbody, isHTML: false)
        
        present(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}

extension UIWebView {
    
    open override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
}
