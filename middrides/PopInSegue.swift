//
//  PopInSegue.swift
//  middrides
//
//  Created by Ben Brown on 2/17/16.
//  Copyright © 2016 Ben Brown. All rights reserved.
//

import UIKit

class PopInSegue: UIStoryboardSegue {
    
    // ----- copied from http://www.appcoda.com/custom-segue-animations/ ----
    override func perform() {
        let firstVCView = source.view as UIView!
        let thirdVCView = destination.view as UIView!
        
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(thirdVCView!, belowSubview: firstVCView!)
        
        thirdVCView?.transform = (thirdVCView?.transform.scaledBy(x: 0.001, y: 0.001))!
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            
            firstVCView?.transform = (thirdVCView?.transform.scaledBy(x: 0.001, y: 0.001))!
            
            }, completion: { (Finished) -> Void in
                
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    thirdVCView?.transform = CGAffineTransform.identity
                    
                    }, completion: { (Finished) -> Void in
                        
                        firstVCView?.transform = CGAffineTransform.identity
                        self.source.present(self.destination as UIViewController, animated: false, completion: nil)
                })
        }) 
    }

}
