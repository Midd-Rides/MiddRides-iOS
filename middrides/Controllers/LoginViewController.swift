//
//  LoginViewController.swift
//  middrides
//
//  Created by Ben Brown on 10/3/15.
//  Copyright © 2015 Ben Brown. All rights reserved.
//

enum LoginType {
    case user
    case dispatcher
    case invalid
}

import UIKit
import Parse
import Bolts

// Extend all UIViewControllers so that they now contain this method
extension UIViewController {
    func displayPopUpMessage(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alertController, animated: false, completion: nil)
    }
    
    func displayPopUpMessageWithBlock(_ title: String, message: String, completionBlock:((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: completionBlock))
        self.present(alertController, animated: false, completion:nil)
    }
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var letsRideButton: UIButton!
    @IBOutlet weak var Password: UITextField!
    @IBOutlet weak var Username: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        Password.delegate = self
        Username.delegate = self
        
        // Disable autocorrect/autosuggest
        Username.autocorrectionType = .no;
        Password.autocorrectionType = .no;
        
        // Synchronize user information from the server. If an error occurs, use
        // the user info stored locally.
        let curUser:PFUser?;
        do{
            print("fetched user from DB")
            curUser = try PFUser.current()?.fetch();
        }catch{
            print("fetching user from db failed. using cached user info");
            curUser = PFUser.current();
        }
        
        if curUser != nil{
            if (curUser!.username == "dispatcher@middlebury.edu"){
                self.performSegue(withIdentifier: "loginViewToDispatcherView", sender: self)
            } else {
                //if user
                if checkAnnouncement() {
                    self.performSegue(withIdentifier: "loginViewToAnnouncementView", sender: self)
                } else {
                    DispatchQueue.main.async {
                        /*solution from stackOverflow answer at http://stackoverflow.com/questions/24982722/performseguewithidentifier-does-not-work
                        */
                        
                        // If the user has verified their email then log them in.
                        if(curUser!["emailVerified"] as! Bool){
                            self.performSegue(withIdentifier: "loginViewToUserView", sender: self);
                        }else{
                            //If not verified, do nothing.
                        }
                    }
                }
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginButtonPressed(letsRideButton)
        
        return true
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        var login = validateLoginCredentials(self.Username.text!, password: self.Password.text!)
        PFUser.logInWithUsername(inBackground: self.Username.text!, password: self.Password.text!) {
            (user: PFUser?, error: Error?) -> Void in
            if user == nil {
                login = .invalid;
            }
            switch login{
            case .user:
                guard let unwrappedUser = user else {
                    print("ERROR: NO USER")
                    return
                }
                
                let emailVerified = unwrappedUser["emailVerified"] as! Bool
                if emailVerified {
                    if self.checkAnnouncement() {
                        self.performSegue(withIdentifier: "loginViewToAnnouncementView", sender: self)
                    } else {
                        self.performSegue(withIdentifier: "loginViewToUserView", sender: self)
                    }
                }
                else {
                    print("ERROR: email not verified")
                    self.displayPopUpMessage("Error", message: "Email not verified")
                }
                
            case .dispatcher:
                self.performSegue(withIdentifier: "loginViewToDispatcherView", sender: self)
                
            case .invalid:
                //display invalid login message
                print("invalid login, username: " + self.Username.text! + " password: " + self.Password.text!)
                self.displayPopUpMessage("Error", message: "Invalid username or password")
            }

        }
        
    }
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        print("register button pressed")
    }
    
    
    
    func validateLoginCredentials(_ username: String, password: String) -> LoginType {
        
        if (username.characters.count <= 15){
            //make sure there username contains string + '@middlebury.edu'
            return .invalid;
        }
        if ((username.hasSuffix("@middlebury.edu")) == false){
            //make sure we have a valid email
            return .invalid;
        }
        
        if (password.characters.count < 6){
            //make sure there are 6 characters in a password
            return .invalid;
        }
        
        
        //TODO: change dispatcher email?
        if (username == "dispatcher@middlebury.edu"){
            return .dispatcher;
        }

        return .user;

    }
    
    func checkAnnouncement() -> Bool {
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Causes the view (or one of its embedded text fields) to resign the first responder status
        // i.e: hide the keyboard
        self.view.endEditing(true);
    }
    
//    @IBAction func resetPasswordButtonPressed(sender: AnyObject) {
//        //TODO: SHERIF DO CODE HERE!
//        //just kidding, shouldn't need any code here
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
