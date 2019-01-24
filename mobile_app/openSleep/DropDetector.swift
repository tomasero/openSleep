//
//  DropDetector.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/6/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

/*
  Measures accelerometer data for drop detection
 */
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
  
  // Starts accelerometers and checks the magnitude for drop detection
  func startAccelerometers() {
    // Make sure the accelerometer hardware is available.
    if self.motion.isAccelerometerAvailable {
      self.motion.accelerometerUpdateInterval = 1.0 / 480.0  // 480 Hz
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
                            self.detectDrop(mag: mag)
                          }
      })
      
      // Add the timer to the current run loop.
      RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
    }
  }
  
  func stopAccelerometers() {
    self.timer.invalidate()
    self.numDrops = 0
  }
  
  func detectDrop(mag: Double) {
    switch(state) {
      case dropState.HELD:
        if(mag > 5) {
          state = dropState.DROPPING
          lastNonZero = NSDate().timeIntervalSince1970
      }
    case dropState.DROPPING:
      if(mag < 3) {
        state = dropState.STOPPED
      }
    case dropState.STOPPED:
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
