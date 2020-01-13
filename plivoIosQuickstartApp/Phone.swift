//
//  Phone.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import Foundation
import PlivoVoiceKit

class Phone {
    
    static let sharedInstance = Phone()
    
    var endpoint: PlivoEndpoint = PlivoEndpoint(["debug": true, "enableTracking":true])
    private var outCall: PlivoOutgoing?
    
    // To register with SIP Server
    func login(withUserName userName: String, andPassword password: String) {
        endpoint.login(userName, andPassword: password)
    }
    
    // To register with SIP Server using device token
    func login(withUserName userName: String, andPassword password: String, deviceToken token: Data) {
        endpoint.login(userName, andPassword: password, deviceToken: token)
    }
    
    //To unregister with SIP Server
    func logout() {
        endpoint.logout()
    }
    
    //receive and pass on (information or a message)
    func relayVoipPushNotification(_ pushdata: [AnyHashable: Any]) {
        endpoint.relayVoipPushNotification(pushdata)
    }
    
    /*
     * To make Call
     * destination number or sipuri
     * extra headers
     * error reference
     * returns outgoing call object
     */
    func call(withDest dest: String, andHeaders headers: [AnyHashable: Any], error: inout NSError?) -> PlivoOutgoing {
        /* construct SIP URI */
        let sipUri: String = "sip:\(dest)\(kENDPOINTURL)"
        /* create PlivoOutgoing object */
        outCall = (endpoint.createOutgoingCall())!
        /* do the call */
        outCall?.call(sipUri, headers: headers, error: &error)
        return outCall!
    }
    
    func setDelegate(_ controllerDelegate: AnyObject) {
        endpoint.delegate = controllerDelegate
    }
    
    //To Configure Audio
    func configureAudioSession() {
        print("----------------- configureAudioSession ")
        endpoint.configureAudioDevice()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeEnded
     */
    func startAudioDevice() {
        print("----------------- startAudioDevice ")
        endpoint.startAudioDevice()
    }
    
    /*
     * To Stop Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeBegan
     */
    func stopAudioDevice() {
        print("----------------- stopAudioDevice ")
        endpoint.stopAudioDevice()
    }
}
