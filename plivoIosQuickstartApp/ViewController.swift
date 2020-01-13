//
//  ViewController.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit
import CallKit
//Display the system-calling UI for your app’s VoIP services, and coordinate your calling services with other apps and the system.
import PlivoVoiceKit
import AVFoundation
//working with time-based audiovisual media ,QuickTime movies and MPEG-4 files, play HLS streams etc

class ViewController: UIViewController, CXProviderDelegate, CXCallObserverDelegate, PlivoEndpointDelegate {
    @IBOutlet weak var loggedinAsLabel: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callStateLabel: UILabel!
    @IBOutlet weak var dialPadView: UIView!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var holdButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var activeCallImageView: UIImageView!
    
    var callObserver: CXCallObserver?
    
    var isItUserAction: Bool = false
    var isItGSMCall: Bool = false
    
    var outCall: PlivoOutgoing?
    var incCall: PlivoIncoming?
    
    var isSpeakerOn: Bool = false
    
    // -----------------------------------------
    //Replace the following values with your SIP URI endpoint and its password
    // -----------------------------------------
    var username: NSString = kUSERNAME as NSString
    var pass: NSString = kPASSWORD as NSString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController did load")
        
        //Login using voipRegistration
        DispatchQueue.main.async(execute: {() -> Void in
            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.voipRegistration()
        })
        
        // Initiate callKitProvider and callObserver
        CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
        CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
        
        //Add Call Interruption observers
        self.addObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Phone.sharedInstance.setDelegate(self)
        hideActiveCallView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UserDefaults.standard.set(false, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        muteButton.isEnabled = false
        holdButton.isEnabled = false
        hideActiveCallView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func onLogin() {
        DispatchQueue.main.async(execute: {() -> Void in
            UtilClass.setUserAuthenticationStatus(true)
            self.loggedinAsLabel.text = self.username as String;
            print("Ready to make a call")
        })
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailed() {
        DispatchQueue.main.async(execute: {() -> Void in
            UtilClass.setUserAuthenticationStatus(false)
            print("%@",kLOGINFAILMSG);
            self.view.isUserInteractionEnabled = true
        })
    }
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    
    func addObservers() {
        // add interruption handler
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        
        // we don't do anything special in the route change notification
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleRouteChange), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        
        // if media services are reset, we need to rebuild our audio chain
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleMediaServerReset), name: AVAudioSession.mediaServicesWereResetNotification, object: AVAudioSession.sharedInstance())
        
//        if the app crashes, we need to terminate the calls
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillTerminate), name: NSNotification.Name.UIApplication.willTerminateNotification, object: nil)

    }
    
    // ----------------------- Incoming -------------------
    
    /**
     * onIncomingCall delegate implementation
     */
    func onIncomingCall(_ incoming: PlivoIncoming) {
        
        switch AVAudioSession.sharedInstance().recordPermission
        {
            case AVAudioSession.RecordPermission.granted:
            
                print("onIncomingCall - Permission is granted to AVAudioSession.RecordPermission ")
                
                DispatchQueue.main.async(execute: {() -> Void in
                    self.userNameTextField.text = ""
                    self.callerNameLabel.text = incoming.fromUser
                    self.callStateLabel.text = "Incoming call..."
                })
                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
//                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue:nil)
//                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue:nil)
                
                if !(incCall != nil) && !(outCall != nil) {
                    print("onIncomingCall - from %@", incoming.fromContact);
                    
                    // assign incCall to incoming call
                    incCall = incoming
                    outCall = nil
                    CallKitInstance.sharedInstance.callUUID = UUID()
                    
                    // Report incoming call to CallKitProvider
                    reportIncomingCall(from: incoming.fromUser, with: CallKitInstance.sharedInstance.callUUID!)
                }
                else {
                     // Reject the call when we already have active ongoing call
                    incoming.reject()
                    return
                }
                break
            
            case AVAudioSession.RecordPermission.denied:
                print("onIncomingCall - Pemission denied to AVAudioSession.RecordPermission")
                print("onIncomingCall - Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                incoming.reject()
                break
            
            case AVAudioSession.RecordPermission.undetermined:
                print("onIncomingCall - Request permission here")
                break
            
            default:
                break
        }
        
    }
    
    /**
     * onIncomingCallHangup delegate implementation.
     */
    func onIncomingCallHangup(_ incoming: PlivoIncoming) {
        print("- Incoming call ended ", incoming.callId);
        if (incCall != nil) {
            self.isItUserAction = true
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
            incCall = nil
        }
    }
    
    /**
     * onIncomingCallRejected implementation.
     */
    func onIncomingCallRejected(_ incoming: PlivoIncoming) {
        print("- On Incoming Call Rejected " , incoming.callId);
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
        incCall = nil
    }
    
    
    // ----------------------- Outgoing -------------------
    
    /**
     * onOutgoingCallAnswered delegate implementation
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing) {
        print("- On outgoing call answered " , call.callId)
        DispatchQueue.main.async(execute: {() -> Void in
            self.muteButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.callStateLabel.text = "Connected"
            
            // Start Audio Device
            Phone.sharedInstance.startAudioDevice()
        })
    }
    
    /**
     * onOutgoingCallHangup delegate implementation.
     */
    func onOutgoingCallHangup(_ call: PlivoOutgoing) {
        print("- On outgoing call Hangup " , call.callId)
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    /**
     * onCalling delegate implementation.
     */
    func onCalling(_ call: PlivoOutgoing) {
        print("- On outgoing Caling " , call.callId)
    }
    
    /**
     * onOutgoingCallRinging delegate implementation.
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing) {
        print("On outgoing Ringing" , call.callId)
        DispatchQueue.main.async(execute: {() -> Void in
            self.callStateLabel.text = "Ringing..."
        })
    }
    
    /**
     * onOutgoingCallrejected delegate implementation.
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing) {
        print("Call id in Rejected is:" , call.callId)
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    /**
     * onOutgoingCallInvalid delegate implementation.
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing) {
        print("Call id in Invalid is:" , call.callId)
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    
    // MARK: - CallKit Actions
    func performStartCallAction(with uuid: UUID, handle: String) {
        
        switch AVAudioSession.sharedInstance().recordPermission {
            
            case AVAudioSession.RecordPermission.granted:
                print("Outgoing call - performStartCallAction AVAudioSession - Permission granted");
                hideActiveCallView()
                unhideActiveCallView()
                
                print("Outgoing call - uuid is: %@", uuid);
                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
                if uuid.uuidString.isEmpty || handle.isEmpty {
                    print("UUID or Handle nil");
                    return
                }
                
                var newHandleString: String = handle.replacingOccurrences(of: "-", with: "")
                if (newHandleString as NSString).range(of: "+91").location == NSNotFound && (newHandleString.count) == 10 {
                    newHandleString = "+91\(newHandleString)"
                }
                let callHandle = CXHandle(type: .generic, value: newHandleString)
                let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
                let transaction = CXTransaction(action:startCallAction)
                CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
                    if error != nil {
                        print("Outgoing call - StartCallAction transaction request failed: %@", error.debugDescription);
                    }
                    else {
                        print("Outgoing call - StartCallAction transaction request successful");
                        let callUpdate = CXCallUpdate()
                        callUpdate.remoteHandle = callHandle
                        callUpdate.supportsDTMF = false
                        callUpdate.supportsHolding = true
                        callUpdate.supportsGrouping = false
                        callUpdate.supportsUngrouping = false
                        callUpdate.hasVideo = false
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.callerNameLabel.text = handle
                            self.callStateLabel.text = "Calling..."
                            self.unhideActiveCallView()
                            print("Outgoing call - performStartCallAction callUpdate" , callUpdate);
                            CallKitInstance.sharedInstance.callKitProvider?.reportCall(with: uuid, updated: callUpdate)
                        })
                    }
                })
                break
            case AVAudioSession.RecordPermission.denied:
                print("Outgoing call - Please go to settings and turn on Microphone service for incoming/outgoing calls.");
                break
            case AVAudioSession.RecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                print("Outgoing call - RecordPermission is turn off for Microphone service on incoming/outgoing calls.");
                break
            default:
                break
        }
    }
    
    /*
     * report Incoming Call
     */
    func reportIncomingCall(from: String, with uuid: UUID) {
        
        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        //Reports a new incoming call with the specified unique identifier to the provider.
        CallKitInstance.sharedInstance.callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: {(_ error: Error?) -> Void in
            if error != nil {
                print("Failed to report incoming call successfully: %@", error.debugDescription);
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    if self.incCall?.state != Ongoing {
                        print("Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        print("Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
            }
            else {
                print("Incoming call - successfully reported.");
                self.callStateLabel.text = "Incoming Call connected"
            }
        })
    }
    
    func performEndCallAction(with uuid: UUID) {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            print("performEndCallActionWithUUID: %@",uuid);
            
            let endCallAction = CXEndCallAction(call: uuid)
            let trasanction = CXTransaction(action:endCallAction)
            CallKitInstance.sharedInstance.callKitCallController?.request(trasanction, completion: {(_ error: Error?) -> Void in
                if error != nil {
                    print("EndCallAction transaction request failed: %@", error.debugDescription);
                    
                    DispatchQueue.main.async(execute: {() -> Void in
                        
                        Phone.sharedInstance.stopAudioDevice()
                        
                        if (self.incCall != nil) {
                            if self.incCall?.state != Ongoing {
                                print("Incoming call - Reject");
                                self.incCall?.reject()
                            }
                            else {
                                print("Incoming call - Hangup");
                                self.incCall?.hangup()
                            }
                            self.incCall = nil
                        }
                        
                        if (self.outCall != nil) {
                            print("Outgoing call - Hangup");
                            self.outCall?.hangup()
                            self.outCall = nil
                        }
                        
                        self.hideActiveCallView()
                        
                    })
                }
                else {
                    print("EndCallAction transaction request successful");
                }
            })
        })
    }

    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            print("CXCallState : Disconnected");
        } else  if call.hasConnected == true {
            print("CXCallState : Connected");
        } else if call.isOutgoing == true {
            print("CXCallState : Dialing");
        } else {
            print("CXCallState : Incoming");
        }
    }
    
    // MARK: - CXProvider Handling
    func providerDidReset(_ provider: CXProvider) {
        print("ProviderDidReset");
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin");
    }
    
    // provider(_:didActivate:) - Called when the provider’s audio session is activated.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession");
        Phone.sharedInstance.startAudioDevice()
    }
    
    // provider(_:didDeactivate:) - Called when the provider’s audio session is deactivated.
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:");
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:");
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider:performStartCallAction:");
        Phone.sharedInstance.configureAudioSession()
        //Set extra headers
        let extraHeaders: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        let dest: String = action.handle.value
        //Make the call
        var error: NSError? = nil
        outCall = Phone.sharedInstance.call(withDest: dest, andHeaders: extraHeaders, error: &error)
        action.fulfill(withDateStarted: Date())
        if (error != nil) {
            outCall = nil
//            print(error?.localizedDescription ?? default "no error")
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:CXSetHeldCallAction:");
        if action.isOnHold {
            Phone.sharedInstance.stopAudioDevice()
        }
        else {
            Phone.sharedInstance.startAudioDevice()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("provider:CXSetMutedCallAction:");
        if action.isMuted {
            muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
        else {
            muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
    }
    
    // provider(_:perform:) - Called when the provider performs the specified answer call action.
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:CXAnswerCallAction");
        Phone.sharedInstance.configureAudioSession()
        //Answer the call
        if (incCall != nil) {
            CallKitInstance.sharedInstance.callUUID = action.callUUID
            incCall?.answer()
        }
        outCall = nil
        //action.fulfill()
        action.fulfill(withDateConnected: Date())
        DispatchQueue.main.async(execute: {() -> Void in
            self.unhideActiveCallView()
            self.muteButton.isEnabled = true
            self.holdButton.isEnabled = true
        })
    }
    
    // provider(_:perform:) - Called when the provider performs the specified end call action.
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        print("provider:CXEndCallAction:");
        DispatchQueue.main.async(execute: {() -> Void in
            if !self.isItGSMCall || self.isItUserAction {
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    if self.incCall?.state != Ongoing {
                        print("Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        print("Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
                
                if (self.outCall != nil) {
                    print("Outgoing call - Hangup");
                    self.outCall?.hangup()
                    self.outCall = nil
                }
                action.fulfill()
                self.isItUserAction = false
                self.hideActiveCallView()
            }
            else {
                print("GSM - provider:performEndCallAction:");
            }
        })
    }
    
    // MARK: - Handling IBActions
    @IBAction func callButtonTapped(_ sender: Any) {
        print(" >> callButtonTapped ")
        switch AVAudioSession.sharedInstance().recordPermission {
                
            case AVAudioSession.RecordPermission.granted:
                
                if (!UtilClass.isEmpty(userNameTextField.text!)) || (incCall != nil) || (outCall != nil) {
                    
                    let img: UIImage? = (sender as AnyObject).image(for: .normal)
                    let data1: NSData? = img!.pngData() as NSData?
                    
                    if (data1?.isEqual(UIImage(named: "MakeCall.png")!.pngData()))! {
                        callStateLabel.text = "Calling..."
                        unhideActiveCallView()
                        var handle: String
                        handle = userNameTextField.text!
                        CallKitInstance.sharedInstance.callUUID = UUID()
                        performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: handle)
                    }
                    else if (data1?.isEqual(UIImage(named: "EndCall.png")!.pngData()))! {
                        callStateLabel.text = "Ending..."
                        isItUserAction = true
                        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
                    }
                }
                else {
                    print(kINVALIDSIPENDPOINTMSG);
                }
                break
            case AVAudioSession.RecordPermission.denied:
                print("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                break
            case AVAudioSession.RecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                print("AVAudioSession.RecordPermission.undetermined")
                break
            default:
                break
            }
    }
    
    /*
     * Mute/Unmute calls
     */
    @IBAction func muteButtonTapped(_ sender: Any) {
        print(" >> muteButtonTapped ")
        
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "Unmute.png")!.pngData()))! {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
        else {
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
    }
    
    /*
     * Hold/Unhold calls
     */
    @IBAction func holdButtonTapped(_ sender: Any) {
        print(" >> holdButtonTapped ")
        
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "UnholdIcon.png")!.pngData()))! {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "HoldIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.hold()
            }
            if (outCall != nil) {
                outCall?.hold()
            }
            Phone.sharedInstance.stopAudioDevice()
            
        }
        else {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unhold()
            }
            if (outCall != nil) {
                outCall?.unhold()
            }
            Phone.sharedInstance.startAudioDevice()
            
        }
    }
    
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
        handleSpeaker()
    }
    
    /*
     * On/Off Speaker
     */
    func handleSpeaker() {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        if(isSpeakerOn)
        {
            self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            isSpeakerOn = false
        }
        else
        {
            self.speakerButton.setImage(UIImage(named: "Speaker_Selected.png"), for: .normal)
            
            /* Enable Speaker Phone mode */
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            
            isSpeakerOn = true
            
        }
    }
    
    func hideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = false
        callerNameLabel.isHidden = true
        callStateLabel.isHidden = true
        activeCallImageView.isHidden = true
        muteButton.isHidden = true
        holdButton.isHidden = true
        dialPadView.isHidden = false
        userNameTextField.isHidden = false
        userNameTextField.isEnabled = true
        callButton.setImage(UIImage(named: "MakeCall.png"), for: .normal)
        callStateLabel.text = "Calling..."
        dialPadView.alpha = 1.0
        dialPadView.backgroundColor = UIColor.white
        handleSpeaker()
        resetCallButtons()
    }
    
    func resetCallButtons() {
        self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
        isSpeakerOn = false
        muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
        self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
    }
    
    func unhideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = true
        callerNameLabel.isHidden = false
        callStateLabel.isHidden = false
        activeCallImageView.isHidden = false
        muteButton.isHidden = false
        holdButton.isHidden = false
        dialPadView.isHidden = true
        userNameTextField.isHidden = true
        callButton.setImage(UIImage(named: "EndCall.png"), for: .normal)
    }
    
    
    /*
     * Handle audio interruptions
     * AVAudioSessionInterruptionTypeBegan
     * AVAudioSessionInterruptionTypeEnded
     */
    @objc func handleInterruption(_ notification: Notification)
    {
        print(" handleInterruption -------- ",notification)
        if self.incCall != nil || self.outCall != nil
        {
            guard let userInfo = notification.userInfo,
                let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue)
                else {
                    return
                }
            
            switch interruptionType {
                
                case .began:
                    print("----------AVAudioSessionInterruptionTypeBegan-------------")
                    self.isItGSMCall = true
                    Phone.sharedInstance.stopAudioDevice()
                    break
                
                case .ended:
                    self.isItGSMCall = false
                    // make sure to activate the session
                    let error: Error? = nil
                    try? AVAudioSession.sharedInstance().setActive(true)
                    if nil != error {
                        print("AVAudioSession set active failed with error")
                        Phone.sharedInstance.startAudioDevice()
                    }
                    print("----------AVAudioSessionInterruptionTypeEnded-------------")
                    break
            }
            
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification)
    {
        print("handleRouteChange");
    }
    
    @objc func handleMediaServerReset(_ notification: Notification) {
        print("Media server has reset");
        // rebuild the audio chain
        Phone.sharedInstance.configureAudioSession()
        Phone.sharedInstance.startAudioDevice()
    }
    
    /*
     * Will be called when app terminates
     * End on going calls(If any)
     */
    @objc func appWillTerminate() {
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }

    /**
     *  Hide keyboard when user touches on UI
     *
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // ...
            if touch.phase == .began
            {
                userNameTextField.resignFirstResponder()
                
            }
        }
        super.touchesBegan(touches, with: event)
    }


}

