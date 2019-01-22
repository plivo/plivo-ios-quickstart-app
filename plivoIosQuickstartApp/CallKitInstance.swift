//
//  CallKitInstance.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit
import CallKit

class CallKitInstance: NSObject {
    
    var callUUID: UUID?
    var callKitProvider: CXProvider?
    var callKitCallController: CXCallController?
    var callObserver: CXCallObserver?
    
    //Singleton instance
    static let sharedInstance = CallKitInstance()
    
    override init() {
        
        super.init()
        
        let providerConfiguration = CXProviderConfiguration(localizedName: "Plivo")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.maximumCallsPerCallGroup = 1
        
        // CXprovider is used for reporting out-of-band notifications that occur to the system
        // such as the call starting, the call being put on hold, or the provider’s audio session being activated.
        callKitProvider = CXProvider(configuration: providerConfiguration)
        
        // CXCallController 
        callKitCallController = CXCallController()
        
        // CXCallObserver is a programmatic interface for an object that manages a list of active calls and observes call changes.
        callObserver = CXCallObserver()
        
    }
    
}
