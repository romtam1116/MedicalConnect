//
//  PatientScanViewController.swift
//  MedicalConsult
//
//  Created by Daniel Yang on 2018-02-06.
//  Copyright © 2018 Loewen-Daniel. All rights reserved.
//

import UIKit
import AVFoundation

class PatientScanViewController: UIViewController {
    
    /// Name for text region layers.
    private let RTRTextRegionsLayerName = "RTRTextRegionLayerName"
    
    /// View with video preview layer
    @IBOutlet weak var previewView: UIView!
    /// View for displaying current area of interest.
    @IBOutlet weak var overlayView: ScanAreaView!
    
    var ivArrowUp: UIImageView! = UIImageView()
    var lblDirection: UILabel! = UILabel()
    var lblInstruction: UILabel! = UILabel()
    var btnCancel: UIButton! = UIButton()
    var btnScan: UIButton! = UIButton()
    
    var results: [RTRTextLine] = []
    var fromConsult: Bool = false
    var fromCreatePatient: Bool = false
    
    /// Camera session.
    private var session: AVCaptureSession?
    /// Video preview layer.
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// Engine for AbbyyRtrSDK.
    private var engine: RTREngine?
    /// Service for runtime recognition.
    private var textCaptureService: RTRTextCaptureService?
    /// Selected recognition languages.
    /// Default recognition language.
    private var selectedRecognitionLanguages = Set(["English"])
    // Recommended session preset.
    private let SessionPreset = AVCaptureSession.Preset.hd1280x720
    private var ImageBufferSize = CGSize(width: 720, height: 1280)
    
    /// Is recognition running.
    private var isRunning = true
    private let RecognitionLanguages = ["English",
                                        "French",
                                        "German",
                                        "Italian",
                                        "Polish",
                                        "PortugueseBrazilian",
                                        "Russian",
                                        "ChineseSimplified",
                                        "ChineseTraditional",
                                        "Japanese",
                                        "Korean",
                                        "Spanish"]
    
    /// Area of interest in view coordinates.
    private var selectedArea: CGRect = CGRect.zero {
        didSet {
            self.overlayView.selectedArea = selectedArea
        }
    }
    
    /// Shortcut. Perform block asynchronously on main thread.
    private func performBlockOnMainThread(_ delay: Double, closure: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
    
    //# MARK: - LifeCycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.clearScreenFromRegions()
        self.initView()
        
        weak var weakSelf = self
        let completion:(Bool) -> Void = { granted in
            weakSelf?.performBlockOnMainThread(0) {
                weakSelf?.configureCompletionAccess(granted)
            }
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case AVAuthorizationStatus.authorized:
            completion(true)
            
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
            
        case AVAuthorizationStatus.restricted, AVAuthorizationStatus.denied:
            completion(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
//        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AppDelegate.AppUtility.lockOrientation(.all)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.session?.stopRunning()
        self.isRunning = false
        self.textCaptureService?.stopTasks()

        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updatePreviewLayerFrame()
        self.updateViewFrames()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let wasRunning = self.isRunning
        self.isRunning = false
        self.textCaptureService?.stopTasks()
        self.clearScreenFromRegions()
        
        coordinator.animate(alongsideTransition: nil) { (context) in
            self.ImageBufferSize = CGSize(width:min(self.ImageBufferSize.width, self.ImageBufferSize.height),
                                          height:max(self.ImageBufferSize.width, self.ImageBufferSize.height))
            if (UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)) {
                self.ImageBufferSize = CGSize(width:self.ImageBufferSize.height, height:self.ImageBufferSize.width);
            }
            
            self.updateAreaOfInterest()
            self.isRunning = wasRunning;
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //# MARK: - Private
    
    func configureCompletionAccess(_ accessGranted: Bool) {
        if !UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear) {
            AlertUtil.showSimpleAlert(self, title: "Camera is not available.", message: nil, okButtonTitle: "OK")
            return
        }
        
        if !accessGranted {
            AlertUtil.showSimpleAlert(self, title: "Camera access is denied.", message: nil, okButtonTitle: "OK")
            return
        }
        
        let licensePath = (Bundle.main.bundlePath as NSString).appendingPathComponent("AbbyyRtrSdk.license")
        self.engine = RTREngine.sharedEngine(withLicense: NSData(contentsOfFile: licensePath) as Data?)
        assert(self.engine != nil)
        guard self.engine != nil else {
            AlertUtil.showSimpleAlert(self, title: "OCR engine error.", message: nil, okButtonTitle: "OK")
            return
        }
        
        self.textCaptureService = self.engine?.createTextCaptureService(with: self)
        self.textCaptureService?.setRecognitionLanguages(selectedRecognitionLanguages)
        
        self.configureAVCaptureSession()
        self.configurePreviewLayer()
        self.session?.startRunning()
        
        NotificationCenter.default.addObserver(self, selector:#selector(PatientScanViewController.avSessionFailed(_:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PatientScanViewController.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PatientScanViewController.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    private func configureAVCaptureSession() {
        self.session = AVCaptureSession()
        
        if let session = self.session {
            session.sessionPreset = SessionPreset
            
            if let device = AVCaptureDevice.default(for: AVMediaType.video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    assert((self.session?.canAddInput(input))!, "impossible to add AVCaptureDeviceInput")
                    self.session?.addInput(input)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else {
                AlertUtil.showSimpleAlert(self, title: "Can't access device for capture video.", message: nil, okButtonTitle: "OK")
                return
            }
            
            let videoDataOutput = AVCaptureVideoDataOutput()
            let videoDataOutputQueue = DispatchQueue(label: "videodataqueue", attributes: .concurrent)
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
            assert((session.canAddOutput(videoDataOutput)), "impossible to add AVCaptureVideoDataOutput")
            session.addOutput(videoDataOutput)
            
            let connection = videoDataOutput.connection(with: AVMediaType.video)
            connection!.isEnabled = true
        }
    }
    
    private func configurePreviewLayer() {
        if let session = self.session {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.previewLayer?.backgroundColor = UIColor.black.cgColor
            self.previewLayer?.videoGravity = AVLayerVideoGravity.resize
            let rootLayer = self.previewView.layer
            rootLayer .insertSublayer(self.previewLayer!, at: 0)
            
            self.updatePreviewLayerFrame()
        }
    }
    
    private func updatePreviewLayerFrame() {
        let orientation = UIApplication.shared.statusBarOrientation
        if let previewLayer = self.previewLayer, let connection = previewLayer.connection {
            connection.videoOrientation = self.videoOrientation(orientation)
            let viewBounds = self.view.bounds
            self.previewLayer?.frame = viewBounds
            
            if (UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)) {
                self.selectedArea = viewBounds.insetBy(dx: 40, dy: viewBounds.height / 3.5)
            } else {
                self.selectedArea = viewBounds.insetBy(dx: 20, dy: viewBounds.height / 8 * 3)
            }
            
            self.updateAreaOfInterest()
        }
    }
    
    private func updateAreaOfInterest() {
        // Scale area of interest from view coordinate system to image coordinates.
        let affineTransform = CGAffineTransform(scaleX: self.ImageBufferSize.width * 1.0 / self.overlayView.frame.width, y: self.ImageBufferSize.height * 1.0 / self.overlayView.frame.height)
        let selectedRect = self.selectedArea.applying(affineTransform)
        self.textCaptureService?.setAreaOfInterest(selectedRect)
    }
    
    private func videoOrientation(_ orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case UIInterfaceOrientation.portrait:
            return AVCaptureVideoOrientation.portrait
        case UIInterfaceOrientation.portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case UIInterfaceOrientation.landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case UIInterfaceOrientation.landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    private func initView() {
        // Initialize views
        let btnFont = UIFont(name: "Avenir-Medium", size: 18) ?? UIFont.systemFont(ofSize: 18)
        
        self.ivArrowUp.image = UIImage(named: "icon_arrow_up")
        
        self.lblDirection.text = "This side up."
        self.lblDirection.textColor = Constants.ColorDarkGray4
        self.lblDirection.textAlignment = .center
        self.lblDirection.font = UIFont(name: "Avenir-Book", size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        self.lblInstruction.text = "Place the label within the guide rectangle."
        self.lblInstruction.textColor = Constants.ColorDarkGray4
        self.lblInstruction.textAlignment = .center
        self.lblInstruction.font = UIFont(name: "Avenir-Book", size: 15) ?? UIFont.systemFont(ofSize: 15)
        
        self.btnCancel.setTitle("Cancel", for: .normal)
        self.btnCancel.setTitleColor(UIColor.white, for: .normal)
        self.btnCancel.backgroundColor = Constants.ColorDarkGray4
        self.btnCancel.layer.cornerRadius = 4.0
        self.btnCancel.layer.masksToBounds = true
        self.btnCancel.titleLabel?.font = btnFont
        self.btnCancel.addTarget(self, action: #selector(cancelPressed(_:)), for: .touchUpInside)
        
        self.btnScan.setTitle("Scan", for: .normal)
        self.btnScan.setTitleColor(UIColor.white, for: .normal)
        self.btnScan.backgroundColor = Constants.ColorDarkGray4
        self.btnScan.layer.cornerRadius = 4.0
        self.btnScan.layer.masksToBounds = true
        self.btnScan.titleLabel?.font = btnFont
        self.btnScan.addTarget(self, action: #selector(scanPressed(_:)), for: .touchUpInside)
        
        self.view.addSubview(self.ivArrowUp)
        self.view.addSubview(self.lblDirection)
        self.view.addSubview(self.lblInstruction)
        self.view.addSubview(self.btnCancel)
        self.view.addSubview(self.btnScan)
        
    }
    
    private func updateViewFrames() {
        // Update view frames
        let viewBounds = self.view.bounds
        
        self.ivArrowUp.frame = CGRect.init(x: viewBounds.width / 2.0 - 74, y: viewBounds.height / 7.0 - 20, width: 40, height: 40)
        self.lblDirection.frame = CGRect.init(x: viewBounds.width / 2.0 - 30, y: viewBounds.height / 7.0 - 10, width: 100, height: 20)
        self.lblInstruction.frame = CGRect.init(x: 20, y: viewBounds.height - viewBounds.height / 3.5 + 12, width: viewBounds.width - 40, height: 20)
        
        self.btnCancel.frame = CGRect.init(x: 16, y: viewBounds.height - 60, width: 100, height: 40)
        self.btnScan.frame = CGRect.init(x: viewBounds.width - 100 - 16, y: viewBounds.height - 60, width: 100, height: 40)
        
    }
    
    //# MARK: - Drawing result
    
    private func drawTextLines(_ textLines: [RTRTextLine], _ progress:RTRResultStabilityStatus) {
        self.clearScreenFromRegions()
        
        let textRegionsLayer = CALayer()
        textRegionsLayer.frame = self.previewLayer!.frame
        textRegionsLayer.name = RTRTextRegionsLayerName
        
        for textLine in textLines {
            self.drawTextLine(textLine, textRegionsLayer, progress)
        }
        
        self.previewView.layer.addSublayer(textRegionsLayer)
    }
    
    func drawTextLine(_ textLine: RTRTextLine, _ layer: CALayer, _ progress: RTRResultStabilityStatus) {
        let topLeft = self.scaledPoint(cMocrPoint: textLine.quadrangle[0] as! NSValue)
        let bottomLeft = self.scaledPoint(cMocrPoint: textLine.quadrangle[1] as! NSValue)
        let bottomRight = self.scaledPoint(cMocrPoint: textLine.quadrangle[2] as! NSValue)
        let topRight = self.scaledPoint(cMocrPoint: textLine.quadrangle[3] as! NSValue)
        
        self.drawQuadrangle(topLeft, bottomLeft, bottomRight, topRight, layer, progress)
        
        let recognizedString = textLine.text
        
        let textLayer = CATextLayer()
        let textWidth = self.distanceBetween(topLeft, topRight)
        let textHeight = self.distanceBetween(topLeft, bottomLeft)
        let rectForTextLayer = CGRect(x: bottomLeft.x, y: bottomLeft.y, width: textWidth, height: textHeight)
        
        // Selecting the initial font size by rectangle
        let textFont = self.font(string: recognizedString!, rect: rectForTextLayer)
        textLayer.font = textFont
        textLayer.fontSize = textFont.pointSize
        textLayer.foregroundColor = self.progressColor(progress).cgColor
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.string = recognizedString
        textLayer.frame = rectForTextLayer
        
        // Rotate the text layer
        let angle = asin((bottomRight.y - bottomLeft.y) / self.distanceBetween(bottomLeft, bottomRight))
        textLayer.anchorPoint = CGPoint(x: 0, y: 0)
        textLayer.position = bottomLeft
        textLayer.transform = CATransform3DRotate(CATransform3DIdentity, angle, 0, 0, 1)
        
        layer.addSublayer(textLayer)
    }
    
    func drawQuadrangle(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ layer: CALayer, _ progress: RTRResultStabilityStatus) {
        let area = CAShapeLayer()
        let recognizedAreaPath = UIBezierPath()
        recognizedAreaPath.move(to: p0)
        recognizedAreaPath.addLine(to: p1)
        recognizedAreaPath.addLine(to: p2)
        recognizedAreaPath.addLine(to: p3)
        recognizedAreaPath.close()
        area.path = recognizedAreaPath.cgPath
        area.strokeColor = self.progressColor(progress).cgColor
        area.fillColor = UIColor.clear.cgColor
        layer.addSublayer(area)
    }
    
    func progressColor(_ progress:RTRResultStabilityStatus) -> UIColor {
        return UIColor(hex: 0x009500)
        
//        switch progress {
//        case RTRResultStabilityStatus.notReady, RTRResultStabilityStatus.tentative:
//            return UIColor(hex: 0xFF6500)
//        case RTRResultStabilityStatus.verified:
//            return UIColor(hex: 0xC96500)
//        case RTRResultStabilityStatus.available:
//            return UIColor(hex: 0x886500)
//        case RTRResultStabilityStatus.tentativelyStable:
//            return UIColor(hex: 0x4B6500)
//        case RTRResultStabilityStatus.stable:
//            return UIColor(hex: 0x006500)
//        }
    }
    
    /// Remove all visible regions
    private func clearScreenFromRegions() {
        // Get all visible regions
        let sublayers = self.previewView.layer.sublayers
        
        // Remove all layers with name - TextRegionsLayer
        for layer in sublayers! {
            if layer.name == RTRTextRegionsLayerName {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    private func scaledPoint(cMocrPoint mocrPoint: NSValue) -> CGPoint {
        let layerWidth = self.previewLayer?.bounds.width
        let layerHeight = self.previewLayer?.bounds.height
        
        let widthScale = layerWidth! / ImageBufferSize.width
        let heightScale = layerHeight! / ImageBufferSize.height
        
        
        var point = mocrPoint.cgPointValue
        point.x *= widthScale
        point.y *= heightScale
        
        return point
    }
    
    private func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let vector = CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)
        return sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
    }
    
    private func font(string: String, rect: CGRect) -> UIFont {
        var minFontSize: CGFloat = 0.1
        var maxFontSize: CGFloat = 72.0
        var fontSize: CGFloat = minFontSize
        
        let rectSize = rect.size
        
        while true {
            let attributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize)]
            let labelSize = (string as NSString).size(withAttributes: attributes)
            
            if rectSize.height - labelSize.height > 0 {
                minFontSize = fontSize
                
                if rectSize.height * 0.99 - labelSize.height < 0 {
                    break
                }
            } else {
                maxFontSize = fontSize
            }
            
            if abs(minFontSize - maxFontSize) < 0.01 {
                break
            }
            
            fontSize = (minFontSize + maxFontSize) / 2
        }
        
        return UIFont.boldSystemFont(ofSize: fontSize)
    }
    
    //# MARK: - Notifications
    
    @objc
    func avSessionFailed(_ notification: NSNotification) {
        AlertUtil.showSimpleAlert(self, title: "AVSession Failed!", message: nil, okButtonTitle: "OK")
    }
    
    @objc
    func applicationDidEnterBackground(_ notification: NSNotification) {
        self.session?.stopRunning()
        self.clearScreenFromRegions()
        self.textCaptureService?.stopTasks()
        self.isRunning = false
    }
    
    @objc
    func applicationWillEnterForeground(_ notification: NSNotification) {
        self.session?.startRunning()
        self.isRunning = true
    }
    
    
    //# MARK: - Actions
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func scanPressed(_ sender: AnyObject) {
        // Scan finished
        if self.fromCreatePatient {
            // Go back to consult referring screen
            let lenght = self.navigationController?.viewControllers.count
            if let createPatientVC = self.navigationController?.viewControllers[lenght! - 2] as? CreatePatientViewController {
                createPatientVC.scanResults = self.results
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: false)
                }
            }
            
        } else {
            // Show create patient screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "CreatePatientViewController") as? CreatePatientViewController {
                vc.scanResults = self.results
                vc.fromRecord = self.fromConsult
                
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
        }
    }
    
    /// Human-readable descriptions for the RTRCallbackWarningCode constants.
    private func stringFromWarningCode(_ warningCode: RTRCallbackWarningCode) -> String {
        var warningString: String
        switch warningCode {
        case .textTooSmall:
            warningString = "Text is too small"
        default:
            warningString = ""
        }
        return warningString
    }
}

extension PatientScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isRunning {
            return
        }
        
        // Image is prepared
        self.performBlockOnMainThread(0) {
            let orientation = UIApplication.shared.statusBarOrientation
            connection.videoOrientation = self.videoOrientation(orientation)
        }
        
        self.textCaptureService?.add(sampleBuffer)
    }
    
}

extension PatientScanViewController: RTRTextCaptureServiceDelegate {
    
    func onBufferProcessed(with textLines: [RTRTextLine]!, resultStatus: RTRResultStabilityStatus) {
        self.performBlockOnMainThread(0) {
            if !self.isRunning {
                return
            }
            
//            if resultStatus == RTRResultStabilityStatus.stable {
//                self.isRunning = false
//                self.textCaptureService?.stopTasks()
//            }
            
            self.results = textLines
            self.drawTextLines(textLines, resultStatus)
        }
    }
    
    func onWarning(_ warningCode: RTRCallbackWarningCode) {
        let message = self.stringFromWarningCode(warningCode);
        if message.count > 0 {
            if(!self.isRunning) {
                return;
            }
            
//            AlertUtil.showSimpleAlert(self, title: message, message: nil, okButtonTitle: "OK")
        }
    }
    
    func onError(_ error: Error!) {
        print(error.localizedDescription)
        performBlockOnMainThread(0) {
            
            if self.isRunning {
                
                var description = error.localizedDescription
                if description.contains("ChineseJapanese.rom") {
                    description = "Chineze, Japanese and Korean are available in EXTENDED version only. Contact us for more information."
                } else if description.contains("KoreanSpecific.rom") {
                    description = "Chineze, Japanese and Korean are available in EXTENDED version only. Contact us for more information."
                } else if description.contains("Russian.edc") {
                    description = "Cyrillic script languages are available in EXTENDED version only. Contact us for more information."
                } else if description.contains(".trdic") {
                    description = "Translation is available in EXTENDED version only. Contact us for more information."
                } else if description.contains("region is invalid") {
                    return
                }
                
//                AlertUtil.showSimpleAlert(self, title: description, message: nil, okButtonTitle: "OK")
                self.isRunning = false
                
            }
            
        }
        
    }

}

extension UIColor {
    
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
    
}
