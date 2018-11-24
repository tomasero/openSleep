//
//  Alerts.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/23/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import Foundation
import UIKit

class Alert {
  @discardableResult init(_ vc : UIViewController, _ message : String) {
    // create the alert
    let alert = UIAlertController(title: "Error!", message: message, preferredStyle: UIAlertController.Style.alert)
    
    // add an action (button)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    
    // show the alert
    vc.present(alert, animated: true, completion: nil)
  }
}

