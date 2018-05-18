//
//  PlayerController.swift
//  MedicalConsult
//
//  Created by Roman Zoffoli on 08/04/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import AVFoundation

class PlayerController {
    
    static let Instance = PlayerController()
    
    var player: AVPlayer?
    var currentIndex: Int?
    var lastPlayed: PlaySlider?
    var elapsedTimeLabel: UILabel?
    var durationLabel: UILabel?
    var playerObserver: Any?
    var shouldSeek: Bool = true
    var timerReset: Timer?
    
    func addObserver() {
        
        guard let _player = self.player as AVPlayer? else {
            return
        }
        
        self.playerObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main) { (CMTime) -> Void in
            
            guard let _lastPlayed = self.lastPlayed as PlaySlider? else {
                return
            }
            
            guard let _currentIndex = self.currentIndex as Int? else {
                return
            }
            
            guard let _playerIndex = _lastPlayed.index as Int? else {
                return
            }
            
            //  Checks if we're updating the correct player.
            if _currentIndex != _playerIndex {
                _lastPlayed.setValue(0.0, animated: false)
                return
            }
            
            if _player.currentItem?.status == .readyToPlay {
                
                var currentTime = CGFloat(_player.currentTime().value) / CGFloat(_player.currentTime().timescale)
                let duration = CGFloat(_player.currentItem!.duration.value) / CGFloat(_player.currentItem!.duration.timescale)
                
                // Seek player only after it's ready to play
                if self.shouldSeek {
                    currentTime = duration * CGFloat((self.lastPlayed?.value)!)
                    print("Just seek to: \(currentTime)")
                    _player.seek(to: CMTimeMakeWithSeconds(Float64(currentTime), _player.currentTime().timescale), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)

                    self.shouldSeek = false
                } else {
                    // Update progress
                    let progress = CGFloat(currentTime) / CGFloat(duration)
                    _lastPlayed.setValue(Float(progress), animated: false)
                }
                
                // Update elapsed time
                if let _elapsedTimeLabel = self.elapsedTimeLabel as UILabel? {
                    _elapsedTimeLabel.text = TimeInterval(currentTime).durationText
                }
                
                // Update duration time
                if let _durationLabel = self.durationLabel as UILabel? {
                    _durationLabel.text = TimeInterval(duration).durationText
                }
                
                // Update state
                if !_lastPlayed.playing && _lastPlayed.value > 0 {
                    _lastPlayed.playing = true
                }
                
            } else if !self.shouldSeek {
                // Reset progress while we're not ready to play
                _lastPlayed.setValue(0.0, animated: false)
                
            }
            
        }
        
    }
    
    func scheduleReset() {
        self.timerReset = Timer.scheduledTimer(timeInterval: 60,
                                               target: self,
                                               selector: #selector(self.resetTimer),
                                               userInfo: nil,
                                               repeats: false)
    }
    
    func invalidateTimer() {
        self.timerReset?.invalidate()
    }
    
    @objc func resetTimer() {
        self.player = nil
    }
    
}
