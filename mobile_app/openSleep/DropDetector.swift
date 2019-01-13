//
//  DropDetector.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/6/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import Foundation
import CoreMotion

class DropDetector : NSObject {
  
  enum dropState {
    case HELD
    case DROPPING
    case STOPPED
    case DROPPED
  }
  
  static let shared = DropDetector()
  let motion = CMMotionManager()
  var timer: Timer!
  var dropCB: (() -> ())? = nil
  
  var numDrops: Int = 0
  
  var state: dropState = .HELD
  var lastNonZero: Double = 0
  
  private override init () {
    super.init()
  }
  
  func setCB(dropCB: @escaping () -> ()) {
    self.dropCB = dropCB
  }
  
  func startAccelerometers() {
    // Make sure the accelerometer hardware is available.
    if self.motion.isAccelerometerAvailable {
      self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
      self.motion.startAccelerometerUpdates()
      
      // Configure a timer to fetch the data.
      self.timer = Timer(fire: Date(), interval: (1.0/480.0),
                         repeats: true, block: { (timer) in
                          // Get the accelerometer data.
                          if let data = self.motion.accelerometerData {
                            let x = data.acceleration.x
                            let y = data.acceleration.y
                            let z = data.acceleration.z
                            let mag = sqrt(pow(x,2) + pow(y,2) + pow(z,2))
                            // Use the accelerometer data in your app.
                            if(mag > 4) {
//                              print("Mag > 4: \(mag)")

                            }
                            self.detectDrop(mag: mag)
                            //States:
                              // HELD
                              // if greater than 8.5 ish Transition to DROPPING, store timestamp
                              // If around 0, check time stamp see if difference is over .05 seconds, see if the mag is 0
                              // Return to HELD
                          }
      })
      
      // Add the timer to the current run loop.
      RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
    }
  }
  
  func detectDrop(mag: Double) {
//    print("Drop STATE,", state)
    switch(state) {
      case dropState.HELD:
//        if(mag > 2) {
//          print("MAG > 2 HELD", mag)
//        }
        if(mag > 7) {
          print("MAG > 7 HELD", mag)
          state = dropState.DROPPING
          lastNonZero = NSDate().timeIntervalSince1970
      }
    case dropState.DROPPING:
//      print("MAG IN DROPPING", mag)
      if(mag < 3) {
        state = dropState.STOPPED
      }
    case dropState.STOPPED:
//      print("MAG IN DROPPED", mag)
      if(mag > 1.1) {
        lastNonZero = NSDate().timeIntervalSince1970
      } else {
        let currentTime = NSDate().timeIntervalSince1970
        if(currentTime - lastNonZero > 0.3) {
          state = dropState.DROPPED
        }
      }
    case dropState.DROPPED:
      numDrops += 1
      print("NUM DROPS:", numDrops)
      if(dropCB != nil) {
        dropCB!()
      }
      state = dropState.HELD
    }
  }
}
