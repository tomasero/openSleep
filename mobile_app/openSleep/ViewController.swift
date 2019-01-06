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

//Declared outside the class to be avalible in the flow view controller as well
enum OnsetTrigger {
  case EDA
  case HR
  case FLEX
  case HBOSS
  case TIMER
}

class ViewController: UIViewController,
                      UITextFieldDelegate,
                      DormioDelegate {

  var dormioManager = DormioManager.shared
  var recordingsManager = RecordingsManager.shared
  
  @IBOutlet weak var flexValue: UILabel!
  @IBOutlet weak var EDAValue: UILabel!
  @IBOutlet weak var HRValue: UILabel!
  @IBOutlet weak var HBOSSLabel: UILabel!
  
  @IBOutlet weak var connectButton: UIButton!
  @IBOutlet weak var recordThinkOfButton: UIButton!
  @IBOutlet weak var recordPromptButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var simulationInput: UISwitch!
  
  @IBOutlet weak var calibrationTimeText: UITextField!
  @IBOutlet weak var promptTimeText: UITextField!
  @IBOutlet weak var numOnsetsText: UITextField!
  @IBOutlet weak var waitForOnsetTimeText: UITextField!
  
  @IBOutlet weak var deltaFlexText: UITextField!
  @IBOutlet weak var deltaHRText: UITextField!
  @IBOutlet weak var deltaEDAText: UITextField!
  @IBOutlet weak var deltaHBOSSText: UITextField!
  
  @IBOutlet weak var meanFlexLabel: UILabel!
  @IBOutlet weak var meanHRLabel: UILabel!
  @IBOutlet weak var meanEDALabel: UILabel!
  
  @IBOutlet weak var uuidLabel: UILabel!
    
  var playedAudio: Bool = false
  var recordingThinkOf: Int = 0 // 0 - waiting for record, 1 - recording, 2 - recorded
  var recordingPrompt: Int = 0 // 0 - waiting for record, 1 - recording, 2 - recorded
  var currentStatus: String = "IDLE"
  var numOnsets = 0
 
  var detectSleepTimer = Timer()
  var detectSleepTimerPause : Bool = false
  
  var edaBuffer = [UInt32]()
  var flexBuffer = [UInt32]()
  var hrBuffer = [UInt32]()
  var hrQueue = HeartQueue(windowTime: 60)
  var lastHrUpdate = Date().timeIntervalSince1970
  
  var isCalibrating = false
  var edaBufferCalibrate = [Int]()
  var flexBufferCalibrate = [Int]()
  var hrBufferCalibrate = [Int]()
  var meanEDA : Int = 0
  var meanHR : Int = 0
  var meanFlex : Int = 0
  var lastEDA : Int = 0
  var lastHR : Int = 0
  var lastFlex : Int = 0
  
  var firstOnset = true
  var lastOnset = Date().timeIntervalSince1970
  
  var timer = Timer()
  var featureImportance : [String : Any] = ["flex" : 0.3,
                                            "eda" : 0.3,
                                            "ecg" : 0.4]
  
  var simulatedData = [[UInt32]]()
  var simulatedIndex: Int = 0
  var simulationTimer = Timer()
  
  var testRecording: Int = 0
  
  var deviceUUID: String = ""
  var sessionDateTime: String = ""
  var getParams = ["String": "String"]
  
  var alarmTimer = Timer()
  var waitTimeForAlarm: Double = 10
  
//  var porcupineManager: PorcupineManager? = nil
  var falsePositive: Bool = false
  
  func dormioConnected() {
    print("Connected")
    self.connectButton.setTitle("CONNECTED", for: .normal)
    self.connectButton.setTitleColor(UIColor.blue, for: .normal)
  }
  
  func dormioDisconnected() {
    self.connectButton.setTitle("CONNECT", for: .normal)
    self.connectButton.setTitleColor(UIColor.red, for: .normal)
  }
  
  func dormioData(hr: UInt32, eda: UInt32, flex: UInt32) {
    flexValue.text = String(flex);
    EDAValue.text = String(eda);
    hrQueue.put(hr: hr)
    if (Date().timeIntervalSince1970 - lastHrUpdate > 1) {
      lastHrUpdate = Date().timeIntervalSince1970
      HRValue.text = String(hrQueue.bpm())
    }
    
    if (self.currentStatus != "IDLE") {
      sendData(flex: flex, hr: hr, eda: eda)
    }
    
    if (self.isCalibrating) {
      calibrateData(flex: flex, hr: hrQueue.bpm(), eda: eda)
    }
  }
  
  func getDeviceUUID() {
    if UserDefaults.standard.object(forKey: "phoneUUID") == nil {
      UserDefaults.standard.set(UUID().uuidString, forKey: "phoneUUID")
    }
    deviceUUID = String(UserDefaults.standard.object(forKey: "phoneUUID") as! String)
    uuidLabel.text = "UUID: "+deviceUUID
    uuidLabel.sizeToFit()
    uuidLabel.center.x = self.view.center.x
    getParams["deviceUUID"] = deviceUUID
  }
  
//  func initPorcupine(keyword:String) {
//    let modelFilePath = Bundle.main.path(forResource:"porcupine_params", ofType: "pv", inDirectory: "./porcupine/common")
//    let keywordCallback: ((WakeWordConfiguration) -> Void) = { _ in
//      self.falsePositive = true
//      self.view.backgroundColor = UIColor.orange
//      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
//        self.view.backgroundColor = UIColor.white
//      }
//    }
//
//    let keywordFilePath = Bundle.main.path(forResource: "porcupine_ios", ofType: "ppn", inDirectory: "./porcupine/resources/keyword_files")
//
//    let wakeWordConfigurations: [WakeWordConfiguration] = [WakeWordConfiguration(name: keyword, filePath: keywordFilePath!, sensitivity: 0.5)]
//
//    do {
//          porcupineManager = try PorcupineManager(modelFilePath: modelFilePath!, wakeKeywordConfigurations: wakeWordConfigurations, onDetection: keywordCallback)
//    }
//    catch {
//
//    }
//
//
//  }
  
  @IBAction func connectButtonPressed(_ sender: UIButton) {
    dormioManager.delegate = self
    if dormioManager.isConnected {
      dormioManager.disconnect()
    } else {
      dormioManager.scanAndConnect()
      self.connectButton.setTitle("SCANNING", for: .normal)
    }
  }
  
  @IBAction func testRecordingsPressed(_ sender: UIButton) {
    recordingsManager.startPlaying(mode: self.testRecording)
    self.testRecording = 1 - self.testRecording
  }
  
  @IBAction func recordThinkOfButtonPressed(sender: UIButton) {
    if (recordingPrompt == 1) {
      return
    }
    if (recordingThinkOf != 1) {
      recordingsManager.startRecording(mode: 0)
      recordingThinkOf = 1;
      recordThinkOfButton.setTitle("Stop", for: .normal)
      recordThinkOfButton.setTitleColor(UIColor.red, for: .normal)
    } else {
      recordingsManager.stopRecording()
      recordingThinkOf = 2;
      recordThinkOfButton.setTitle("Record\n\"You can fall asleep now,\nRemember to think of... \"", for: .normal)
      recordThinkOfButton.setTitleColor(UIColor.lightGray, for: .normal)
    }
    
  }
  
  @IBAction func recordPromptButtonPressed(sender: UIButton) {
    
    if (recordingThinkOf == 1) {
      return
    }
    if (recordingPrompt != 1) {
      recordingsManager.startRecording(mode: 1)
      recordingPrompt = 1;
      recordPromptButton.setTitle("Stop", for: .normal)
      recordPromptButton.setTitleColor(UIColor.red, for: .normal)
    } else {
      recordingsManager.stopRecording()
      recordingPrompt = 2;
      recordPromptButton.setTitle("Record\n\"You're falling asleep...\nTell me what you're thinking\"", for: .normal)
      recordPromptButton.setTitleColor(UIColor.lightGray, for: .normal)
    }
    
  }
  
  @IBAction func startButtonPressed(sender: UIButton) {
  
    if (currentStatus == "IDLE") {
      startButton.setTitle("WAITING", for: .normal)
      startButton.setTitleColor(UIColor.red, for: .normal)
      currentStatus = "CALIBRATING"
      
      if (simulationInput.isOn) {
        self.simulatedIndex = 0
        self.simulationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.simulator(sender:)), userInfo: nil, repeats: true)
      }
      
      self.detectSleepTimer.invalidate()
      
      SleepAPI.apiGet(endpoint: "init", params: getParams, onSuccess: {json in
        self.sessionDateTime = json["datetime"] as! String
        self.getParams["datetime"] = self.sessionDateTime
        
      })
      self.startButton.setTitle("CALIBRATING", for: .normal)
      self.calibrateStart()
      self.numOnsets = 0
      
      recordingsManager.calibrateSilenceThreshold()
      
      self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {
        t in
        self.recordingsManager.startPlaying(mode: 0)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.calibrationTimeText.text!)! - 30, repeats: false, block: {
          t in
          self.startButton.setTitle("WAITING FOR SLEEP", for: .normal)
          self.currentStatus = "RUNNING"
          self.calibrateEnd()
          
          SleepAPI.apiGet(endpoint: "train", params: self.getParams)
          
          self.detectSleepTimerPause = false
          self.detectSleepTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.detectSleep(sender:)), userInfo: nil, repeats: true)
        })
      })
      
    } else if (currentStatus == "CALIBRATING" || currentStatus == "RUNNING") {
        reset()
    }
  }
  
  func reset() {
    startButton.setTitle("START", for: .normal)
    startButton.setTitleColor(UIColor.blue, for: .normal)
    currentStatus = "IDLE"
    playedAudio = false
    falsePositive = false
    self.calibrateEnd()
    self.timer.invalidate()
    self.detectSleepTimer.invalidate()
    self.alarmTimer.invalidate()
    
    self.recordingsManager.reset()
    
    if (simulationInput.isOn) {
      self.simulationTimer.invalidate()
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let defaults = UserDefaults.standard
    calibrationTimeText?.text = String(defaults.object(forKey: "calibrationTime") as! Int)
    promptTimeText?.text = String(defaults.object(forKey: "promptTime") as! Int)
    numOnsetsText?.text = String(defaults.object(forKey: "numOnsets") as! Int)
    waitForOnsetTimeText?.text = String(defaults.object(forKey: "waitForOnsetTime") as! Int)
    deltaHBOSSText?.text = String(defaults.object(forKey: "deltaHBOSS") as! Int)
    deltaEDAText?.text = String(defaults.object(forKey: "deltaEDA") as! Int)
    deltaHRText?.text = String(defaults.object(forKey: "deltaHR") as! Int)
    deltaFlexText?.text = String(defaults.object(forKey: "deltaFlex") as! Int)
    var data = readDataFromCSV(fileName: "simulatedData", fileType: "csv")
    data = cleanRows(file: data!)
    self.simulatedData = csv(data: data!)
    
    getDeviceUUID()
//    initPorcupine(keyword: "porcupine")
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
    if (self.simulatedIndex >= self.simulatedData.count) {
      self.simulatedIndex = 0
    }
    self.sendData(flex: self.simulatedData[self.simulatedIndex][0], hr: self.simulatedData[self.simulatedIndex][1], eda: self.simulatedData[self.simulatedIndex][2])
    self.EDAValue.text = String(self.simulatedData[self.simulatedIndex][2])
    hrQueue.put(hr: self.simulatedData[self.simulatedIndex][1])
    self.HRValue.text = String(hrQueue.bpm())
    self.flexValue.text = String(self.simulatedData[self.simulatedIndex][0])
    self.simulatedIndex += 1
    if (self.simulatedIndex == 845) {
      print("##### Sending SLEEP data! #####")
    }
  }
  
  @objc func detectSleep(sender: Timer) {
    //let json : [String: Any] = ["feature_importance" : self.featureImportance]
    
    var onsetTrigger: OnsetTrigger?
    
    SleepAPI.apiGet(endpoint: "predict", params: self.getParams, onSuccess: { json in
      let score = Int((json["max_sleep"] as! NSNumber).floatValue.rounded())
      DispatchQueue.main.async {
        self.HBOSSLabel.text = String(score)
        
        if (!self.detectSleepTimerPause && self.numOnsets == 0 && score >= Int(self.deltaHBOSSText.text!)!) {
          
          onsetTrigger = (onsetTrigger == nil) ? OnsetTrigger.HBOSS : onsetTrigger
          self.sleepDetected(trigger: onsetTrigger!)
          self.HBOSSLabel.textColor = UIColor.red
        }
      }
    })
    
    if (!detectSleepTimerPause) {
      var detected = false
      if (abs(lastHR - meanHR) >= Int(deltaHRText.text!)!) {
        HRValue.textColor = UIColor.red
        detected = true
        onsetTrigger = (onsetTrigger == nil) ? OnsetTrigger.HR : onsetTrigger
      }
      if (abs(lastEDA - meanEDA) >= Int(deltaEDAText.text!)!) {
        EDAValue.textColor = UIColor.red
        detected = true
        onsetTrigger = (onsetTrigger == nil) ? OnsetTrigger.EDA : onsetTrigger
      }
      if (abs(lastFlex - meanFlex) >= Int(deltaFlexText.text!)!) {
        flexValue.textColor = UIColor.red
        detected = true
        onsetTrigger = (onsetTrigger == nil) ? OnsetTrigger.FLEX : onsetTrigger
      }
      if (detected) {
        DispatchQueue.main.async {
          self.sleepDetected(trigger: onsetTrigger!)
        }
      }
    }
  }
  
  func sleepDetected(trigger: OnsetTrigger) {
    self.timer.invalidate()
    print("Sleep!")
    print("TRIGGER WAS", String(describing: trigger))

    var json: [String : Any] = ["trigger" : String(describing: trigger),
                                "currDateTime" : Date().timeIntervalSince1970,
                                "deviceUUID": deviceUUID,
                                "datetime": sessionDateTime]

    if (!self.playedAudio) {
      self.playedAudio = true
      self.startButton.setTitle("SLEEP!", for: .normal)
      self.detectSleepTimerPause = true
      // pause timer
      self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.promptTimeText.text!)!, repeats: false, block: {
        t in
        
        self.falsePositive = false

        
        self.recordingsManager.startPlaying(mode: 1)
        self.numOnsets += 1

        self.recordingsManager.doOnPlayingEnd = {
          self.startButton.setTitle("RECORDING", for: .normal)
          self.recordingsManager.startRecordingDream(dreamTitle: "Experiment", silenceCallback: { () in
            
            self.recordingsManager.stopRecording()
            
            json["legitimate"] = !self.falsePositive
            SleepAPI.apiPost(endpoint: "reportTrigger", json: json)
            print("SILENCE DETECTED!")
            if (self.numOnsets < Int(self.numOnsetsText.text!)!) {
                self.transitionOnsetToSleep()
            } else {
                self.alarmTimer = Timer.scheduledTimer(withTimeInterval: self.waitTimeForAlarm, repeats: false, block: { (t) in
                  self.reset()
                  self.recordingsManager.alarm()
                  self.wakeupAlarm()
                })
            }
            
          })
          
        }
        self.calibrateStart()
        
        
      })
    }
  }
  
func transitionOnsetToSleep() {
    recordingsManager.startPlaying(mode: 0)
    playedAudio = false
    startButton.setTitle("WAITING FOR SLEEP", for: .normal)
    detectSleepTimerPause = false
    calibrateEnd()
    
    self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.waitForOnsetTimeText.text!)!, repeats: false, block: {
      t in
      self.sleepDetected(trigger: OnsetTrigger.TIMER)
    })
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func wakeupAlarm() {
    print("NO MORE ONSETS TO DETECT")
    let alert = UIAlertController(title: "Wakeup!", message: "Dreamcatcher has caught \(self.numOnsets) dream(s).", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
      if(action.style == .cancel) {
        print("Alarm Alert Dismissed")
        self.recordingsManager.stopAlarm()
      }
    }))
    self.present(alert, animated: true, completion: nil)
  }
  
  func sendData(flex: UInt32, hr: UInt32, eda: UInt32) {
    flexBuffer.append(flex)
    edaBuffer.append(eda)
    hrBuffer.append(hr)
    

    
    if (flexBuffer.count >= 30) {
      // send buffer to server
      let json: [String : Any] = ["flex" : flexBuffer,
                                  "eda" : edaBuffer,
                                  "ecg" : hrBuffer,
                                  "deviceUUID": deviceUUID,
                                  "datetime": sessionDateTime]
      SleepAPI.apiPost(endpoint: "upload", json: json)
      
      lastEDA = Int(Float(edaBuffer.reduce(0, +)) / Float(edaBuffer.count))
      lastFlex = Int(Float(flexBuffer.reduce(0, +)) / Float(flexBuffer.count))
      lastHR = hrQueue.bpm()
      
      flexBuffer.removeAll()
      edaBuffer.removeAll()
      hrBuffer.removeAll()
    }
  }
  
  func calibrateData(flex: UInt32, hr: Int, eda: UInt32) {
    flexBufferCalibrate.append(Int(flex))
    edaBufferCalibrate.append(Int(eda))
    hrBufferCalibrate.append(Int(hr))
  }
  
  func calibrateStart() {
    flexBufferCalibrate.removeAll()
    edaBufferCalibrate.removeAll()
    hrBufferCalibrate.removeAll()
    isCalibrating = true
  }
  
  func calibrateEnd() {
    if hrBufferCalibrate.count > 0 {
      meanHR = Int(Float(hrBufferCalibrate.reduce(0, +)) / Float(hrBufferCalibrate.count))
      meanEDA = Int(Float(edaBufferCalibrate.reduce(0, +)) / Float(edaBufferCalibrate.count))
      meanFlex = Int(Float(flexBufferCalibrate.reduce(0, +)) / Float(flexBufferCalibrate.count))
      isCalibrating = false
      
      meanHRLabel.text = String(meanHR)
      meanEDALabel.text = String(meanEDA)
      meanFlexLabel.text = String(meanFlex)
    }
    
    self.HRValue.textColor = UIColor.black
    self.flexValue.textColor = UIColor.black
    self.EDAValue.textColor = UIColor.black
    self.HBOSSLabel.textColor = UIColor.black
  }

  @IBAction func waitForOnsetTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(waitForOnsetTimeText.text!), forKey: "waitForOnsetTime")
  }
  @IBAction func maxOnsetsChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(numOnsetsText.text!), forKey: "numOnsets")
  }
  @IBAction func promptTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(promptTimeText.text!), forKey: "promptTime")
  }
  @IBAction func calibrationTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(calibrationTimeText.text!), forKey: "calibrationTime")
  }
  @IBAction func HBOSSChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaHBOSSText.text!), forKey: "deltaHBOSS")
  }
  @IBAction func flexChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaFlexText.text!), forKey: "deltaFlex")
  }
  @IBAction func HRChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaHRText.text!), forKey: "deltaHR")
  }
  @IBAction func EDAChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaEDAText.text!), forKey: "deltaEDA")
  }
}
