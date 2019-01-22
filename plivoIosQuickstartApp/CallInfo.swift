//
//  CallInfo.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit

class CallInfo: NSObject {
    
    /**
     *  Add recent calls info
     *
     *  @param callInfo contains Phone number or SIP Endpoit, Time of call
     */
    
    class func addCallsInfo(callInfo: [Any])
    {
        var callInfoArrayOld = UserDefaults.standard.object(forKey: kCALLSINFO) as? [Any] ?? [Any]()
        
        if callInfoArrayOld.isEmpty {
            callInfoArrayOld = [Dictionary <String, Date>]()
        }
        
        var callInfoArrayNew = [Any]()
        callInfoArrayNew+=callInfoArrayOld
        callInfoArrayNew.append(callInfo)
        
        UserDefaults.standard.set(callInfoArrayNew, forKey: kCALLSINFO)
        UserDefaults.standard.synchronize()
        
    }
    
    /**
     *  Return recent calls info
     *
     */
    class func getCallsInfoArray() -> [Any] {
        
        let callInfoArray = UserDefaults.standard.object(forKey: kCALLSINFO) as? [Any] ?? [Any]()
        
        return callInfoArray.reversed()
        
    }
}
