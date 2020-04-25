//
//  ID.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/30/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import Foundation


public struct ID {
  var deviceID: String?
  var sessionDateTime: String?
  
  init() {

  }
  
  mutating func newSessionId(){
    self.sessionDateTime = UUID().uuidString;
  }
}
