//
//  Flow.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/25/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import Foundation

class FlowManager : NSObject {
  static let shared = FlowManager()

  var dreamTitle : String?
  var dreamStage : Int = 0
  var numOnsets : Int = 3

  private override init () {
    super.init()
  }
  
  func promptTimeDelay() -> Double {
    if dreamStage == 0 {
      return 30
    } else if dreamStage == 1 {
      return 60
    } else if dreamStage == 2 {
      return 90
    }
    return 0
  }
  
}

