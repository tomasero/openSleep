//
//  FlexAnalyzer.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/25/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import Foundation

class FlexAnalyzer: NSObject {
  
  enum FlexState {
    case OPEN
    case CLOSING
    case CLOSED
    case OPENING
  }
  
  let openThresh: Int = 650
  let closedThresh: Int = 430
  
  var state: FlexState = .OPEN
  var openTransitionTime: Double = 0
  var CloseTimeThresh: Double = 1.75 // at least one second in closed to detect False Positive
  
  var numFlexes: Int = 0
  
  var numFalsePositives: Int = 0
  
  var falsePositive: Bool = false
  
  static let shared = FlexAnalyzer()
  
  private override init () {
    super.init()
  }
  
  func isFalsePositive()->Bool {
    if(falsePositive) {
      falsePositive = false
      return true
    }
    return false
  }
  
  func resetFalsePositive() {
    falsePositive = false
  }
  
  func detectFalsePositive(flex: UInt32) {
    
    switch(state) {
    case FlexState.OPEN:
      if (flex <= openThresh) {
        state = .CLOSING
        openTransitionTime = NSDate().timeIntervalSince1970
      }
    case FlexState.CLOSING:
      if (flex > openThresh) {
        state = .OPEN
        break
      }
      else if(flex <= closedThresh) {
        state = .CLOSED
      }
    case FlexState.CLOSED:
      if(flex > closedThresh) {
        state = .OPENING
        break
      }
      if(NSDate().timeIntervalSince1970 - openTransitionTime <= CloseTimeThresh) {
        numFlexes += 1
        state = .OPENING
        if(numFlexes == 2) {
          numFlexes = 0
          numFalsePositives += 1
          print("NumFalse Positives:", numFalsePositives)
          falsePositive = true
        }
      }
    case FlexState.OPENING:
      if(flex >= openThresh) {
        state = .OPEN
      }
    }
  }
  
}
