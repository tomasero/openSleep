//
//  AppDelegate.swift
//  blueMarc
//
//  Created by Tomas Vega on 12/7/17.
//  Copyright © 2017 Tomas Vega. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    let defaults = UserDefaults.standard
    if defaults.object(forKey: "calibrationTime") == nil {
      defaults.set(300, forKey: "calibrationTime")
    }
    if defaults.object(forKey: "promptTime") == nil {
      defaults.set(15, forKey: "promptTime")
    }
    if defaults.object(forKey: "numOnsets") == nil {
      defaults.set(3, forKey: "numOnsets")
    }
    if defaults.object(forKey: "waitForOnsetTime") == nil {
      defaults.set(240, forKey: "waitForOnsetTime")
    }
    if defaults.object(forKey: "deltaHBOSS") == nil {
      defaults.set(7, forKey: "deltaHBOSS")
    }
    if defaults.object(forKey: "deltaFlex") == nil {
      defaults.set(50, forKey: "deltaFlex")
    }
    if defaults.object(forKey: "deltaHR") == nil {
      defaults.set(15, forKey: "deltaHR")
    }
    if defaults.object(forKey: "deltaEDA") == nil {
      defaults.set(10, forKey: "deltaEDA")
    }
    if defaults.object(forKey: "minTimeToFirstOnset") == nil {
      defaults.set(300, forKey:"minTimeToFirstOnset")
    }
    if defaults.object(forKey:"falsePosFlexOpen") == nil {
      defaults.set(750, forKey:"falsePosFlexOpen")
    }
    if defaults.object(forKey:"falsePosFlexClosed") == nil {
      defaults.set(430, forKey:"falsePosFlexClosed")
    }
    if defaults.object(forKey: "minRecordingTime") == nil {
      defaults.set(30, forKey:"minRecordingTime")
    }
    if defaults.object(forKey:"maxRecordingTime") == nil {
      defaults.set(120, forKey:"maxRecordingTime")
    }
    if defaults.object(forKey: "maxTimeToFirstOnset") == nil {
      defaults.set(600, forKey:"maxTimeToFirstOnset")
    }
    if defaults.object(forKey: "phoneUUIDPrefix") == nil {
      defaults.set("subject", forKey:"phoneUUIDPrefix")
    }
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


}

