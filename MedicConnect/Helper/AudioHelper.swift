//
//  AudioHelper.swift
//  MedicalConsult
//
//  Created by Roman Zoffoli on 03/04/17.
//  Copyright © 2017 Loewen-Daniel. All rights reserved.
//

import AVFoundation

class AudioHelper {
    
    static var overrideMode: AVAudioSessionPortOverride = .speaker
    
    static func SetCategory(mode: AVAudioSessionPortOverride) {
        
        do {
            
            if mode == .speaker {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions(rawValue: AVAudioSessionCategoryOptions.RawValue(UInt8(AVAudioSessionCategoryOptions.defaultToSpeaker.rawValue) | UInt8(AVAudioSessionCategoryOptions.allowBluetoothA2DP.rawValue))))
                try AVAudioSession.sharedInstance().setActive(true)
                
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.allowBluetoothA2DP)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(mode)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            
            self.overrideMode = mode
            
        } catch {
            print(error)
        }
        
    }
    
}
