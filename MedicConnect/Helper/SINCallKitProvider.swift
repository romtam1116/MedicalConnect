//
//  SINCallKitProvider.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-03-22.
//  Copyright © 2018 Loewen. All rights reserved.
//

import CallKit

class SINCallKitProvider: NSObject, CXProviderDelegate {
    
    init(withClient client: SINClient) {
        
    }
    
    func reportNewIncomingCall(_ call: SINCall) {
        
    }
    
    func callExists(_ callId: String) -> Bool {
        
        return true
    }
    
//    func currentEstablishedCall() -> SINCall {
//
//    }
    
    func providerDidReset(_ provider: CXProvider) {
        
    }
    
}
