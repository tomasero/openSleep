//
//  Dormio.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/24/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

protocol DormioDelegate where Self:  UIViewController  {
  func dormioData(hr: UInt32, eda: UInt32, flex: UInt32)
  func dormioConnected()
  func dormioDisconnected()
}

class DormioManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  static let shared = DormioManager()
  
  public var delegate : DormioDelegate?
  
  var manager:CBCentralManager!
  var _peripheral:CBPeripheral!
  var sendCharacteristic: CBCharacteristic!
  public var isConnected: Bool = false
  
  let NAME = "RFduino"
  let UUID_SERVICE = CBUUID(string: "2220")
  let UUID_READ = CBUUID(string: "2221")
  let UUID_WRITE = CBUUID(string: "2222")
  
  private override init() {
    super.init()
    manager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func scanAndConnect() {
    if manager.state == CBManagerState.poweredOn {
      manager.scanForPeripherals(withServices: nil, options: nil)
    } else {
      Alert(delegate as! UIViewController, "Bluetooth is off or BLE is not supported")
    }
  }
  
  func disconnect() {
    manager.cancelPeripheralConnection(_peripheral)
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    /*
    if central.state == CBManagerState.poweredOn {
      print("Scanning...")
      central.scanForPeripherals(withServices: nil, options: nil)
    }
    */
  }
  
  // Found a peripheral
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    //    print("found a peripheral")
    // Device
    let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
    // Check if this is the device we want
    if device?.contains(NAME) == true {
      
      // Stop looking for devices
      // Track as connected peripheral
      // Setup delegate for events
      self.manager.stopScan()
      self._peripheral = peripheral
      self._peripheral.delegate = self
      
      // Connect to the perhipheral proper
      manager.connect(peripheral, options: nil)
      
      // Debug
      debugPrint("Found Bean.")
    }
  }
  
  // Connected to peripheral
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // Ask for services
    peripheral.discoverServices(nil)
    
    // Debug
    debugPrint("Getting services ...")
  }
  
  // Discovered peripheral services
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    // Look through the service list
    for service in peripheral.services! {
      let thisService = service as CBService
      
      // If this is the service we want
      print(service.uuid)
      if service.uuid == UUID_SERVICE {
        // Ask for specific characteristics
        peripheral.discoverCharacteristics(nil, for: thisService)
        
        // Debug
        debugPrint("Using scratch.")
      }
      
      // Debug
      debugPrint("Service: ", service.uuid)
    }
  }
  
  // Discovered peripheral characteristics
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    debugPrint("Enabling ...")
    
    // Look at provided characteristics
    for characteristic in service.characteristics! {
      let thisCharacteristic = characteristic as CBCharacteristic
      
      // If this is the characteristic we want
      print(thisCharacteristic.uuid)
      if thisCharacteristic.uuid == UUID_READ {
        // Start listening for updates
        // Potentially show interface
        self._peripheral.setNotifyValue(true, for: thisCharacteristic)
        
        isConnected = true
        if let d = delegate {
          d.dormioConnected()
        }
        
        // Debug
        debugPrint("Set to notify: ", thisCharacteristic.uuid)
      } else if thisCharacteristic.uuid == UUID_WRITE {
        sendCharacteristic = thisCharacteristic
      }
      
      // Debug
      debugPrint("Characteristic: ", thisCharacteristic.uuid)
    }
  }
  
  // Data arrived from peripheral
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    //    print("Data")
    // Make sure it is the peripheral we want
    //    print(characteristic.uuid)
    if characteristic.uuid == UUID_READ {
      // Get bytes into string
      let dataReceived = characteristic.value! as NSData
      var flex: UInt32 = 0
      var EDA: UInt32 = 0
      var HR: UInt32 = 0
      dataReceived.getBytes(&flex, range: NSRange(location: 0, length: 4))
      dataReceived.getBytes(&HR, range: NSRange(location: 4, length: 4))
      dataReceived.getBytes(&EDA, range: NSRange(location: 8, length: 4))
      
      if let d = delegate {
        d.dormioData(hr: HR, eda: EDA, flex: flex)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    print("success")
    print(characteristic.uuid)
    print(error)
  }
  
  // Peripheral disconnected
  // Potentially hide relevant interface
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    debugPrint("Disconnected.")
    
    isConnected = false
    if let d = delegate {
      d.dormioDisconnected()
    }
        
    // Start scanning again
    // central.scanForPeripherals(withServices: nil, options: nil)
  }

  /*
 func getData() -> NSData{
 let state: UInt16 = stateValue ? 1 : 0
 let power:UInt16 = UInt16(thresholdValue)
 var theData : [UInt16] = [ state, power ]
 print(theData)
 let data = NSData(bytes: &theData, length: theData.count)
 return data
 }
 
 func updateSettings() {
 if loadedService {
 if _peripheral?.state == CBPeripheralState.connected {
 if let characteristic:CBCharacteristic? = sendCharacteristic{
 let data: Data = getData() as Data
 _peripheral?.writeValue(data,
 for: characteristic!,
 type: CBCharacteristicWriteType.withResponse)
 }
 }
 }
 }
 */
}
