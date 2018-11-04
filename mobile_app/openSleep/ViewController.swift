//
//  ViewController.swift
//  blueMarc
//
//  Created by Tomas Vega on 12/7/17.
//  Copyright © 2017 Tomas Vega. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation
import MediaPlayer

let storedItemsKey = "storedItems"

class ViewController: UIViewController,
                      CBCentralManagerDelegate,
                      CBPeripheralDelegate,
                      AVAudioRecorderDelegate,
                      AVAudioPlayerDelegate {
  
  var manager:CBCentralManager!
  var _peripheral:CBPeripheral!
  var sendCharacteristic: CBCharacteristic!
  var loadedService: Bool = true
  
  let synth = AVSpeechSynthesizer()
  var recordingSession : AVAudioSession!
  var audioRecorder    :AVAudioRecorder!
  var audioRecorderSettings = [String : Int]()
  var audioPlayer : AVAudioPlayer!
  var audioURLs = [Int: URL]()
  
  let NAME = "RFduino"
  let UUID_SERVICE = CBUUID(string: "2220")
  let UUID_READ = CBUUID(string: "2221")
  let UUID_WRITE = CBUUID(string: "2222")
  
  @IBOutlet weak var stateInput: UISwitch!
  @IBOutlet weak var thresholdInput: UISlider!
  
  @IBOutlet weak var flexValue: UILabel!
  @IBOutlet weak var EDAValue: UILabel!
  @IBOutlet weak var HRValue: UILabel!
  @IBOutlet weak var thresholdLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var simulationInput: UISwitch!
  
  var stateValue: Bool = false
//  var modeValue: Int = 0
  var thresholdValue: Int = 0
  
  var playedAudio: Bool = false
  var isRecording: Bool = false
  var currentStatus: String = "IDLE"
 
  var apiBaseURL: String = "http://68.183.114.149:5000/"
  var detectSleepTimer = Timer()
  
  var edaBuffer = [UInt32]()
  var flexBuffer = [UInt32]()
  var hrBuffer = [UInt32]()
  
  var simulatedData = [[UInt32]]()
  var simulatedIndex: Int = 0
  var simulationTimer = Timer()
  
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
  
  @IBAction func stateChanged(_ sender: UISwitch) {
    print("STATE CHANGED")
    stateValue = stateInput.isOn
    print(stateValue)
    if !stateValue {
//      thresholdInput.isEnabled = false
//      thresholdInput.tintColor = UIColor .gray
    } else {
//      thresholdInput.isEnabled = true
//      thresholdInput.tintColor = modeValue == 0 ? UIColor .red : UIColor .blue
    }
//    updateSettings()
  }
//
//  @IBAction func modeChanged(_ sender: UISegmentedControl) {
//    print("MODE CHANGED")
//    modeValue = modeInput.selectedSegmentIndex
//    if modeValue == 0 {
//      thresholdInput.tintColor = UIColor .red
//    } else {
//      thresholdInput.tintColor = UIColor .blue
//    }
//    updateSettings()
//  }
  
  @IBAction func thresholdChanged(_ sender: UISlider) {
    thresholdValue = Int(thresholdInput.value)
    thresholdLabel.text = String(thresholdValue)
    updateSettings()
  }
  
  @IBAction func recordButtonPressed(sender: UIButton) {
    if (!isRecording) {
      self.startRecording()
      isRecording = true;
      recordButton.setTitle("Stop", for: .normal)
      recordButton.setTitleColor(UIColor.red, for: .normal)
    } else {
      audioRecorder.stop()
      isRecording = false;
      recordButton.setTitle("Record", for: .normal)
      recordButton.setTitleColor(UIColor.blue, for: .normal)
    }
    
  }
  
  @IBAction func startButtonPressed(sender: UIButton) {
    if (currentStatus == "IDLE") {
      startButton.setTitle("Cancel", for: .normal)
      startButton.setTitleColor(UIColor.red, for: .normal)
      currentStatus = "RUNNING"
      
      self.apiGet(endpoint: "init")
      
      if (simulationInput.isOn) {
        self.simulatedIndex = 0
        self.simulationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.simulator(sender:)), userInfo: nil, repeats: true)
      }
      
      _ = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: {
        t in
        self.startButton.setTitle("Start", for: .normal)
        self.startButton.setTitleColor(UIColor.blue, for: .normal)
        self.currentStatus = "CALIBRATED"
      })
    } else if (currentStatus == "CALIBRATED") {
      startButton.setTitle("Cancel", for: .normal)
      startButton.setTitleColor(UIColor.red, for: .normal)
      currentStatus = "RUNNING"
      
      self.apiGet(endpoint: "train")

      self.detectSleepTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.detectSleep(sender:)), userInfo: nil, repeats: true)
    } else if (currentStatus == "RUNNING") {
      startButton.setTitle("Calibrate", for: .normal)
      startButton.setTitleColor(UIColor.blue, for: .normal)
      currentStatus = "IDLE"
      
      self.detectSleepTimer.invalidate()
      
      if (simulationInput.isOn) {
        self.simulationTimer.invalidate()
      }
    }
  }
  func audioDirectoryURL(_ number: Int) -> NSURL? {
    let id: String = String(number)
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let soundURL = documentDirectory.appendingPathComponent("sound_\(id).m4a")
    print(soundURL!)
    return soundURL as NSURL?
  }
  
  func startRecording() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      let url = self.audioDirectoryURL(0)! as URL
      audioRecorder = try AVAudioRecorder(url: url,
                                          settings: audioRecorderSettings)
      audioRecorder.delegate = self
      audioRecorder.prepareToRecord()

      audioURLs[0] = url
      print("url = \(url)")
    } catch {
      audioRecorder.stop()
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
    } catch {
    }
  }
  
  func startPlaying() {
    self.audioPlayer = try! AVAudioPlayer(contentsOf: audioURLs[0]!)
    self.audioPlayer.prepareToPlay()
    self.audioPlayer.delegate = self
//    self.audioPlayer.currentTime = max(0 as TimeInterval, self.audioPlayer.duration - audioPlaybackOffset)
    self.audioPlayer.play()
  }

  
  override func viewDidLoad() {
    super.viewDidLoad()
    manager = CBCentralManager(delegate: self, queue: nil)
    stateInput.setOn(false, animated: false)
//    enableModeInput(enable: true)
//    thresholdInput.isEnabled = false
    thresholdInput.value = 0.0
//    thresholdInput.isContinuous = false;
    
    // Do any additional setup after loading the view, typically from a nib.
    stateValue = stateInput.isOn
    thresholdValue = 0
    
    // Audio recording session
    recordingSession = AVAudioSession.sharedInstance()
    do {
      try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission() { [unowned self] allowed in
        DispatchQueue.main.async {
          if allowed {
            print("Allow")
          } else {
            print("Dont Allow")
          }
        }
      }
    } catch {
      print("failed to record!")
    }
    
    // Audio Settings
    audioRecorderSettings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    var data = readDataFromCSV(fileName: "simulatedData", fileType: "csv")
    data = cleanRows(file: data!)
    self.simulatedData = csv(data: data!)
  }
  
  func readDataFromCSV(fileName:String, fileType: String)-> String!{
    guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
      else {
        return nil
    }
    do {
      var contents = try String(contentsOfFile: filepath, encoding: .utf8)
      contents = cleanRows(file: contents)
      return contents
    } catch {
      print("File Read Error for file \(filepath)")
      return nil
    }
  }
  
  func cleanRows(file:String)->String{
    var cleanFile = file
    cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
    cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
    //        cleanFile = cleanFile.replacingOccurrences(of: ";;", with: "")
    //        cleanFile = cleanFile.replacingOccurrences(of: ";\n", with: "")
    return cleanFile
  }
  
  func csv(data: String) -> [[UInt32]] {
    var result: [[UInt32]] = []
    let rows = data.components(separatedBy: "\n")
    for row in rows {
      let columns = row.components(separatedBy: ",").map{ UInt32($0)! }
      result.append(columns)
    }
    return result
  }

  @objc func simulator(sender: Timer) {
    if (self.simulatedIndex > self.simulatedData.count) {
      self.simulatedIndex = 0
    }
    self.sendData(flex: self.simulatedData[self.simulatedIndex][0], hr: self.simulatedData[self.simulatedIndex][1], eda: self.simulatedData[self.simulatedIndex][2])
    self.EDAValue.text = String(self.simulatedData[self.simulatedIndex][2])
    self.HRValue.text = String(self.simulatedData[self.simulatedIndex][1])
    self.flexValue.text = String(self.simulatedData[self.simulatedIndex][0])
    self.simulatedIndex += 1
    if (self.simulatedIndex == 845) {
      print("##### Sending SLEEP data! #####")
    }
  }
  
  @objc func detectSleep(sender: Timer) {
    self.apiGet(endpoint: "predict", onSuccess: { json in
      let score = (json["mean_sleep"] as! NSNumber).floatValue
      DispatchQueue.main.async {
        self.statusLabel.text = String(score)
      }
      
      if (score > 0.5) {
        print("Sleep!")
        if (!self.playedAudio) {
          //self.startPlaying()
          self.playedAudio = true
        }
      }
    })
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == CBManagerState.poweredOn {
      print("Buscando a Marc")
      central.scanForPeripherals(withServices: nil, options: nil)
    }
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
        
        // Debug
        debugPrint("Set to notify: ", thisCharacteristic.uuid)
      } else if thisCharacteristic.uuid == UUID_WRITE {
        sendCharacteristic = thisCharacteristic
        loadedService = true
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
      dataReceived.getBytes(&EDA, range: NSRange(location: 4, length: 4))
      dataReceived.getBytes(&HR, range: NSRange(location: 8, length: 4))
//      print(out1)
//      print(out2)
//      print(out3)
      flexValue.text = String(flex);
      EDAValue.text = String(EDA);
      HRValue.text = String(HR);
      
      sendData(flex: flex, hr: HR, eda: EDA)
      
      if (stateValue) {
        if (flex < thresholdValue) {
          if (playedAudio) { return }
//          print("hello motto")
//          let utterance = AVSpeechUtterance(string: "Hello Motto")
//          utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
//          synth.speak(utterance)
          startPlaying()
          playedAudio = true
        } else {
          playedAudio = false;
        }
      }
      
//
//      let firstChunk = characteristic.value![0...3]
//      var values = [UInt32](repeating: 0, count:characteristic.value!.count)
//      let myData = [UInt32](values)
//      print(myData)
////
//      // Convert bytes to integer (we know this number)
//      print(firstChunk)
//      var firstBuffer: Int = 0
//      let numberFromChunk = d.getBytes(&firstBuffer, length: 4)
////      firstChunk.getBytes(&firstBuffer, length: 4)
      
//      print(numberFromChunk)
      
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
    
    // Start scanning again
    central.scanForPeripherals(withServices: nil, options: nil)
  }
    
  func sendData(flex: UInt32, hr: UInt32, eda: UInt32) {
    flexBuffer.append(flex)
    edaBuffer.append(eda)
    hrBuffer.append(hr)
    
    if (flexBuffer.count >= 30) {
      // send buffer to server
      let json: [String : Any] = ["flex" : flexBuffer,
                                  "eda" : edaBuffer,
                                  "ecg" : hrBuffer]
      self.apiPost(endpoint: "upload", json: json)
      
      flexBuffer.removeAll()
      edaBuffer.removeAll()
      hrBuffer.removeAll()
    }
  }
  
  func apiGet(endpoint: String, onSuccess: (([String : Any]) -> ())? = nil) {
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
  
  func apiPost(endpoint: String, json: [String: Any]) {
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
          
        }
      } catch let error {
        print(error.localizedDescription)
      }
    }
    task.resume()  }

}
