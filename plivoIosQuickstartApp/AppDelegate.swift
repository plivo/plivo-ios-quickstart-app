//
//  AppDelegate.swift
//  plivoIosQuickstartApp
//
//  Created by Altanai Bisht on 12/11/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit
import PushKit
import AVFoundation
import Intents
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate  {
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        //For VOIP Notificaitons
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
        application.registerForRemoteNotifications()
        
        //Request Record permission
        //audio session acts as an intermediary between your app and the operating system—and, in turn, the underlying audio hardware.
        let audioSession = AVAudioSession.sharedInstance()
        if (audioSession.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("AVAudioSession permission - granted ")
                    do {
                        try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: .defaultToSpeaker)
                        try audioSession.setActive(true)
                    }
                    catch {
                        print("AVAudioSession permission - Couldn't set Audio session category")
                    }
                } else{
                    print("AVAudioSession permission - not granted")
                }
            })
        }
        
        let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller: ViewController? = _mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        window?.rootViewController = controller
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // Register for VoIP notifications
    func voipRegistration() {
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipResistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipResistry.delegate = (self as PKPushRegistryDelegate)
        //Set the push type to VOIP
        voipResistry.desiredPushTypes = Set<AnyHashable>([PKPushType.voIP]) as? Set<PKPushType>
    }

}
