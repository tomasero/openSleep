//
//  SleepAPI.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/24/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import Foundation

final class SleepAPI {
  static let apiBaseURL: String = "http://68.183.114.149:5000/"
  
  static func apiGet(endpoint: String, onSuccess: (([String : Any]) -> ())? = nil) {
    let url = URL(string: self.apiBaseURL + endpoint)
    print("GET " + self.apiBaseURL + endpoint)
    let task = URLSession.shared.dataTask(with: url!){ (data, response, error) in
      guard error == nil else {
        print(error!)
        return
      }
      
      guard let data = data else {
        print("No data received")
        return
      }
      
      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
          guard json["status"] as! Int == 0 else {
            print("Error!")
            print(json)
            return
          }
          if let callableOnSuccess = onSuccess {
            callableOnSuccess(json)
          }
        }
      } catch let error {
        print(error.localizedDescription)
      }
    }
    task.resume()
  }

  static func apiPost(endpoint: String, json: [String: Any], onSuccess: (([String : Any]) -> ())? = nil) {
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    let url = URL(string: self.apiBaseURL + endpoint)
    print("POST " + self.apiBaseURL + endpoint)
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
      guard error == nil else {
        print(error!)
        return
      }
      
      guard let data = data else {
        print("No data received")
        return
      }
      
      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
          guard json["status"] as! Int == 0 else {
            print("Error!")
            print(json)
            return
          }
          if let callableOnSuccess = onSuccess {
            callableOnSuccess(json)
          }
        }
      } catch let error {
        print(error.localizedDescription)
      }
    }
    task.resume()
    
  }
  
}
