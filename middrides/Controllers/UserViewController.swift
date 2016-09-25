//
//  UserViewController.swift
//  middrides
//
//  Created by Ben Brown on 11/17/15.
//  Copyright © 2015 Ben Brown. All rights reserved.
//

import UIKit
import Parse

class UserViewController: UIViewController {

    let TIME_OUT = 0.0
    let ERROR_TITLE = "ERROR"
    let ERROR_MESSAGE = "Time-out message"
    let ACTION_TITLE = "OK"
    
    @IBOutlet weak var requestVanButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var requestInfoLabel: UILabel!
    
    var hiddenControls: Bool = false {
        // After setting the hiddenControls variable, adjust the rest of the view accordingly
        didSet {
            // view or hide the cancel and request info according to hiddenControls
            cancelButton.isHidden = hiddenControls
            requestInfoLabel.isHidden = hiddenControls
            
            // If we are making them visible, query Parse for the requested stop location
            // and show that location to the user
            if !hiddenControls {
                requestInfoLabel.text = "We'll notify you when your van is coming!"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = PFUser.current() {
//            user.
            if let pendingRequest = user["pendingRequest"] as? Bool {
                print(pendingRequest);
                if pendingRequest {
                    print(1);
                    hiddenControls = false
                } else {
                    print(2);
                    hiddenControls = true
                }
            } else {
                print(3);
                hiddenControls = true
            }
        }
        
        // Add a listener to change the info label when dispatcher sends push
        NotificationCenter.default.addObserver(self, selector: #selector(UserViewController.displayVanArrivingMessage(_:)), name: NSNotification.Name(rawValue: "vanArriving"), object: nil);

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //function that checks if the user has made a request in the past TIME_OUT seconds
    func checkTimeOut() -> Bool {
        
        // Check if it has been more than TIME_OUT seconds since the last request
        
        var timeSinceLastRequest = TimeInterval(TIME_OUT + 1)
        let dateNow = Date(timeIntervalSinceNow: 0)
        
        
        if let dateSinceLastRequest = UserDefaults.standard.object(forKey: "dateSinceLastRequest") as? Date {
            timeSinceLastRequest = dateNow.timeIntervalSince(dateSinceLastRequest)
        }

        return timeSinceLastRequest > TIME_OUT
    }
    
    @IBAction func requestVanButtonPressed(_ sender: UIButton) {
        if checkTimeOut() {
            if hiddenControls {

                self.performSegue(withIdentifier: "userViewToVanRequestView", sender: self)
            } else {
                self.displayPopUpMessage("Error", message: "Cannot make two van requests at the same time")
            }
        } else {
            self.displayPopUpMessage("Error", message: "Cannot make van requests within 5 minutes of each other");
        }
    }

    /**
    Cancels the current request and displays a success message
     
     TODO: Handle cancellation failures
    */
    @IBAction func cancelRequestButtonPressed(_ sender: UIButton) {
        cancelCurrentRequest();
        
        //display message
        self.displayPopUpMessage("Success", message: "Van request canceled")
        hiddenControls = true
    }
        
    /**
    Cancels the current van request by doing the following: 
        * Delete all of the user's current requests from the UserRequest table
        * Unsubscribes from Parse push notifications
        * Decrements the LocationStatus class by 1 in the row of the requested stop
        * Sets Parse pendingRequest to false in the User table
        * Sets our local pendingRequest variable to false
    */
    func cancelCurrentRequest() -> Void {
        
        //update Parse User and UserRequest
        if let user = PFUser.current() {
            user["pendingRequest"] = false;
            
            if let userId = user.objectId {
                let query = PFQuery(className: "UserRequest")
                query.whereKey("userId", equalTo: userId)
                query.findObjectsInBackground() { (objects: [PFObject]?, error: Error?) -> Void in
                    if let unwrappedObjects = objects {
                        for object in unwrappedObjects {
                            var locName = object["pickUpLocation"] as? String
                            locName = locName!.replacingOccurrences(of: " ", with: "-")
                            locName = locName!.replacingOccurrences(of: "/", with: "-")
                            PFPush.unsubscribeFromChannel(inBackground: locName!)
                            object.deleteEventually()
                        }
                    }
                }
            }
            
            user.saveInBackground();
        }
        
        /* update Parse LocationStatus */
        
        //Get the location of pending/current request
        let pendingRequestLocation = UserDefaults.standard.object(forKey: "pendingRequestLocation");
        
        if let unwrappedLocationName = pendingRequestLocation as? String {
            print("\(unwrappedLocationName)");
            let query = PFQuery(className: "LocationStatus")
            query.whereKey("name", equalTo: unwrappedLocationName)
            query.findObjectsInBackground() { (objects: [PFObject]?, error: Error?) -> Void in
                if let unwrappedObjects = objects {
                    if (unwrappedObjects[0]["passengersWaiting"] as! Int) > 0 {
                        
                        print("unwrapped location: \(unwrappedObjects[0])");
                        let numPassengers = unwrappedObjects[0]["passengersWaiting"] as! Int
                        unwrappedObjects[0]["passengersWaiting"] = numPassengers - 1
                    }
                    unwrappedObjects[0].saveInBackground()
                }
            }
        }
        
        //Update local variables
        UserDefaults.standard.set(false, forKey: "pendingRequest");
    }
    
    func displayVanArrivingMessage(_ sender: AnyObject) -> Void{
        if let user = PFUser.current() {
            
            user["pendingRequest"] = false;
            user.saveInBackground();
            
            if let userId = user.objectId {
                let query = PFQuery(className: "UserRequest")
                query.whereKey("userId", equalTo: userId)
                query.findObjectsInBackground() { (objects: [PFObject]?, error: Error?) -> Void in
                    if let unwrappedObjects = objects {
                        // Get the stopname of the latest request, and display that to the user
                        let lastRequestIndex = unwrappedObjects.count - 1;
                        let object = unwrappedObjects[lastRequestIndex]
                        let name = object["pickUpLocation"] as! String
                        self.requestInfoLabel.text = "Your van is en route to\n" + name
                        self.requestInfoLabel.font = UIFont.systemFont(ofSize: 20);
                    }
                }
            }
        }
        
        // Hide the "cancel request" button
        self.cancelButton.isHidden = true;
        
        // When the user receives a push, we want to reset the screen after 5 minutes
        // Since we presume that by then, the van has arrived to the stop
        let FIVE_MINUTES:Double = 5 * 60;
        
        runAfterDelay(FIVE_MINUTES){
            print("Run delayed code bock to reset the screen");
            
            // First change locally
            UserDefaults.standard.set(false, forKey: "pendingRequest");
            
            // Reset the screen back to normal
            self.hiddenControls = true;
            
            // Remove the local notification from the notification center in the iPhone
            for notification in UIApplication.shared.scheduledLocalNotifications as [UILocalNotification]! { // loop through notifications...
                
                if let pushId = UserDefaults.standard.object(forKey: "currentPushId"){
                    // and cancel the notification that corresponds to this notification instance (matched by UUID)
                    if (notification.userInfo!["UUID"] as! String == pushId as! String) {
                        // there should be a maximum of one match on UUID, so we break the loop once
                        // we find it
                        UIApplication.shared.cancelLocalNotification(notification)
                        break
                    }
                }
            }
        };
    }
    
    @IBAction func logoutButtonPressed(_ sender: AnyObject) {
        // If the user has requested a van and is trying to logout, they should be informed.
        let logoutConfirmation = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout? This will cancel any requests you have placed.", preferredStyle: UIAlertControllerStyle.alert)
        
        logoutConfirmation.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // If user confirms logout
            self.cancelCurrentRequest();
            PFUser.logOutInBackground() {(error: Error?) in
                self.performSegue(withIdentifier: "userViewToLoginView", sender: self)
            }
        }))
        
        logoutConfirmation.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            //If user cancels, nothing happens
        }))
        
        present(logoutConfirmation, animated: true, completion:  nil)
    }
    
    /*
     * Runs a given code block after an n second delay
     */
    func runAfterDelay(_ delay: TimeInterval, block: @escaping ()->()) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
        DispatchQueue.main.asyncAfter(deadline: time, execute: block);
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
