//
//  CustonSegue1.swift
//  middrides
//
//  Created by Ben Brown on 2/16/16.
//  Copyright © 2016 Ben Brown. All rights reserved.
//

import UIKit

class SlideFromRightSegue: UIStoryboardSegue {
    
    
    // ----- copied from http://www.appcoda.com/custom-segue-animations/ ----
    override func perform() {
        // Assign the source and destination views to local variables.
        let firstVCView = self.source.view as UIView!
        let secondVCView = self.destination.view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        // Specify the initial position of the destination view.
        secondVCView?.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(secondVCView!, aboveSubview: firstVCView!)
        
        // Animate the transition.
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            firstVCView?.frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
            secondVCView?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            
            }, completion: { (Finished) -> Void in
                self.source.present(self.destination as UIViewController,
                    animated: false,
                    completion: nil)
        }) 
    }
}
