//
//  AppDelegate.swift
//  middrides
//
//  Created by Ben Brown on 10/3/15.
//  Copyright © 2015 Ben Brown. All rights reserved.
//

import UIKit
import Parse
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pushRespController:PushResponseController?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Parse.
        Parse.setApplicationId("II5Qw9I5WQ5Ezo9mL8TdYj3mEoiSFcdt8GFMAgsm",
            clientKey: "EIepTgb590NQw5DDu1EccT7YvprP2ovLesj1t3Nd");
        
        self.pushRespController = PushResponseController();
        
        /*---------FROM PARSE WEBSITE-----------*/
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
            let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }
        if #available(iOS 8.0, *) {
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types: UIRemoteNotificationType = [.alert, .badge, .sound]
            application.registerForRemoteNotifications(matching: types)
        }
        
        /*-------------------------------------*/
        
        /*
        if (application.respondsToSelector("registerUserNotificationSettings:")){
            //if iOS8+
            
            let types:UIUserNotificationType = (.Alert | .Badge | .Sound);
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil);
            application.registerUserNotificationSettings(settings);
            application.registerForRemoteNotifications();
        } else {
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound);
        }
        */
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /*---------FROM PARSE WEBSITE-----------*/
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation.setDeviceTokenFrom(deviceToken)
        installation.saveInBackground()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error._code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Called in background");
        self.application(application, didReceiveRemoteNotification: userInfo);
        if(application.applicationState == UIApplicationState.inactive){
            print("inactive");
        }else if (application.applicationState == UIApplicationState.background){
            print("background");
        } else{
            print("Active");
        }
        completionHandler(UIBackgroundFetchResult.newData);
    }
    
    //Handle push notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print(userInfo)
        PFPush.handle(userInfo)
        let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        let nextDest = userInfo["location"] as! String
        
        //unsubscribe from necessary channel
        var channelName = nextDest.replacingOccurrences(of: " ", with: "-")
        channelName = channelName.replacingOccurrences(of: "/", with: "-")
        PFPush.unsubscribeFromChannel(inBackground: channelName)
        let msg = "Your van is headed to " + nextDest + " now!"     ;
        
        // create a local notification
        let notification = UILocalNotification()
        notification.alertBody = msg // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        // When notification will be fired
        notification.fireDate = Date(timeIntervalSinceNow: 5);
        // play default sound
        notification.soundName = UILocalNotificationDefaultSoundName
        // assign a unique identifier to the notification so that we can retrieve it later
        notification.userInfo = ["UUID": userInfo["parsePushId" ]!, ]
        UIApplication.shared.scheduleLocalNotification(notification)
        
        //Save the reference to the notification so we can remove it later
        UserDefaults.standard.set(userInfo["parsePushId"], forKey: "currentPushId");
        
        //Notify other views that the van is arriving so they update accordingly
        NotificationCenter.default.post(name: Notification.Name(rawValue: "vanArriving"), object: nil);
        
        var curView = self.window?.rootViewController
        /*
        'while' loop with presented view controller based on top answer here:
        http://stackoverflow.com/questions/26667009/get-top-most-uiviewcontroller
        */
        while ((curView?.presentedViewController) != nil){
            curView = curView?.presentedViewController
        }
        

        let alert = UIAlertController(title: "MiddRides Notice!", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(okButton)
        
        curView!.present(alert, animated: true, completion: nil)
        
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }
    
    /*-------------------------------------*/

}

