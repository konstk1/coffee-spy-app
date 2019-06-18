//
//  AppDelegate.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/25/19.
//  Copyright © 2019 KK. All rights reserved.
//

import UIKit
import CoreData
import SwiftyBeaver

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let console = ConsoleDestination()
        console.levelColor.verbose = "◻️ "
        console.levelColor.debug   = "◼️ "
        console.levelColor.info    = "🔷 "
        console.levelColor.warning = "🔶 "
        console.levelColor.error   = "🛑 "
        
        
        log.addDestination(console)
        
        if let secrets = getPlist(named: "Secrets"),
           let appID = secrets["SwiftyBeaverAppID"], let appSecret = secrets["SwiftyBeaverAppSecret"], let encryptionKey = secrets["SwiftyBeaverEncryptionKey"] {
            let cloud = SBPlatformDestination(appID: appID, appSecret: appSecret, encryptionKey: encryptionKey)
            cloud.analyticsUserName = "coffee-spy"
            log.verbose("Adding SB cloud log destination")
            log.addDestination(cloud)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        dataController.saveMainContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        dataController.saveMainContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        dataController.saveMainContext()
    }
}

