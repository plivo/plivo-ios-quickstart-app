//
//  UtilClass.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration


class UtilClass: NSObject
{
    
    static let utilitySharedInstance = UtilClass()
    
    /**
     *  set User's authentication status
     *  @param status of the user's authentication
     */
    class func setUserAuthenticationStatus(_ status: Bool) {
        UserDefaults.standard.set(status, forKey: kAUTHENTICATIONSTATUS)
        UserDefaults.standard.synchronize()
    }
    
    /**
     *  get Status of the user's authentication
     *  @return true if user is valid user
     */
    class func getUserAuthenticationStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kAUTHENTICATIONSTATUS)
    }
    
    /*
     * To check empty string
     */
    class func isEmpty(_ text: String) -> Bool {
        return (text.isEmpty || true == (self.trimWhiteSpaces(text) == "")) ? true : false
    }
    
    /*
     * To trim white spaces in string
     */
    class func trimWhiteSpaces(_ text: String) -> String {
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
 

}
