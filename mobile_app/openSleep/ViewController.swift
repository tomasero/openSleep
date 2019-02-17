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

// Triggers reported to the prediction server
enum OnsetTrigger {
  case EDA
  case HR
  case FLEX
  case HBOSS
  case TIMER
}

class ViewController: UIViewController,
                      UITextFieldDelegate,
                      UIPopoverPresentationControllerDelegate,
                      DormioDelegate {

  var dormioManager = DormioManager.shared
  var recordingsManager = RecordingsManager.shared
  
  var flexAnalyzer = FlexAnalyzer.shared
  
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
  
  @IBOutlet weak var uuidLabel: UILabel! // Display UUID in experimental mode to cross reference with filenames on server
  @IBOutlet weak var uuidPrefixText: UITextField!
  
  @IBOutlet weak var infoButton: UIButton! // Button near nav bar to provide descriptions for parameters in experimental mode
  
  @IBOutlet weak var falsePosFlexOpenText: UITextField!
  @IBOutlet weak var falsePosFlexClosedText: UITextField!
  
  @IBOutlet weak var minRecordingTimeText: UITextField!
  @IBOutlet weak var maxRecordingTimeText: UITextField!
  
  @IBOutlet weak var maxTimeToFirstOnsetText: UITextField!
  
  @IBOutlet weak var speakingDetectionInput: UISwitch!
  
  var maxTimeToFirstOnsetTimer = Timer()
  
  var playedAudio: Bool = false
  var recordingThinkOf: Int = 0 // 0 - waiting for record, 1 - recording, 2 - recorded
  var recordingPrompt: Int = 0 // 0 - waiting for record, 1 - recording, 2 - recorded
  var currentStatus: String = "IDLE"
  var numOnsets = 0
 
  var detectSleepTimer = Timer()
  var detectSleepTimerPause : Bool = false
  
  var falsePositiveTimer = Timer()
  var falsePositiveTimerInterval = 0.5
  
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
  
  var deviceUUID: String = "" // UUID generated once, sent to server to name model and data files
  var sessionDateTime: String = "" // Used to uniquely identify a session
  var getParams: [String: String] = [:]// parameters sent with get api calls to server
  
  var alarmTimer = Timer() // Timer used to trigger an alarm after the final onset is detected
  var waitTimeForAlarm: Double = 10.0 // How long to wait after the last onset to trigger the alarm
  
//  var porcupineManager: PorcupineManager? = nil
  var falsePositive: Bool = false // whether the detected onset was a false positive
  
  var sleepIsDetected: Bool = false
  
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
    
    if(sleepIsDetected) {
      flexAnalyzer.detectFalsePositive(flex: flex)
    }

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
  
  /*
    Checks if device uuid is in local storage, if not creates one
    Adds the deviceUUID to the getParams dictionary
 */
  func getDeviceUUID()-> String {
    if UserDefaults.standard.object(forKey: "phoneUUID") == nil {
      UserDefaults.standard.set(UUID().uuidString, forKey: "phoneUUID")
    }
    deviceUUID = String(UserDefaults.standard.object(forKey: "phoneUUID") as! String)
    
    if let prefix = UserDefaults.standard.object(forKey: "phoneUUIDPrefix"){
      if (prefix as! String) != "" {
        deviceUUID = (prefix as! String) + "-" + deviceUUID
      }
      uuidPrefixText.text = prefix as! String
    }
    uuidLabel.text = "UUID: "+deviceUUID
    uuidLabel.sizeToFit()
    uuidLabel.center.x = self.view.center.x
    getParams["deviceUUID"] = deviceUUID
    return deviceUUID
  }
  
  func setUUIDPrefix(_ prefix: String) {
    UserDefaults.standard.set(prefix, forKey: "phoneUUIDPrefix")
    getDeviceUUID()
  }
  
  /*
    Initialize porcupine keyword detection - currently needs work if integrated into dormio
   - Pocrupine listens for audio in one format, and the recordings manager does so in another format, need to either have recordingManger
        record audio in the same format, or have porcupine handle recording audio as well as keyword detection
 */
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
    recordingsManager.startPlaying(mode: 1) // Right now, only plays back the "wake up prompt" audio message, since users now have ability
                                            // to record more than one "Remember to think of..." messages
  }
  
  /*
    Pushes the table listing all the "Remember to think of..." recordings to view
 */
  @IBAction func recordThinkOfButtonPressed(sender: UIButton) {
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let newViewController = storyBoard.instantiateViewController(withIdentifier: "thinkOfTable") as! ThinkOfRecordingTableViewController
    self.navigationController?.pushViewController(newViewController, animated: true)
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
    
    getDeviceUUID()
    
    if (currentStatus == "IDLE") {
      startButton.setTitle("WAITING", for: .normal)
      startButton.setTitleColor(UIColor.red, for: .normal)
      currentStatus = "CALIBRATING"
      
      if (simulationInput.isOn) {
        self.simulatedIndex = 0
        self.simulationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.simulator(sender:)), userInfo: nil, repeats: true)
      }
      
      self.detectSleepTimer.invalidate()
      
      setFalsePositiveFlexParams()
      setRecordingTimes()

      //TODO also send the parameters, deltas, to the server
      let initParams = getInitParams()
      SleepAPI.apiGet(endpoint: "init", params: initParams, onSuccess: {json in
        self.sessionDateTime = json["datetime"] as! String
        self.getParams["datetime"] = self.sessionDateTime
        print("Sent these params: ", initParams,"getParams:", self.getParams)
      })
      
      self.startButton.setTitle("CALIBRATING", for: .normal)
      self.calibrateStart()
      self.numOnsets = 0
      
      recordingsManager.calibrateSilenceThreshold() // calculates a decible level used to later detect silence
      
      self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {
        t in
        self.recordingsManager.startPlayingMulti(mode: 0, numOnset: self.numOnsets)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.calibrationTimeText.text!)! - 30, repeats: false, block: {
          t in
          self.startButton.setTitle("WAITING FOR SLEEP", for: .normal)
          self.currentStatus = "RUNNING"
          self.calibrateEnd()
          
          SleepAPI.apiGet(endpoint: "train", params: self.getParams)
          
          self.detectSleepTimerPause = false
          self.detectSleepTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.detectSleep(sender:)), userInfo: nil, repeats: true)
          
          if(self.speakingDetectionInput.isOn) {
            self.recordingsManager.startSpeakingDetectionRecording("Experiment", onSpeechCB: self.onNonPromptSpeech)
          }
        })
        
        self.maxTimeToFirstOnsetTimer = Timer.scheduledTimer(withTimeInterval: Double(self.maxTimeToFirstOnsetText.text!)! - 30, repeats: false, block: {
          t in
            print("Triggering first Onset after max time of", self.maxTimeToFirstOnsetText.text!)
            self.sleepDetected(trigger: .TIMER)
        })
      })
      
    } else if (currentStatus == "CALIBRATING" || currentStatus == "RUNNING") {
        reset() // reset back to starting state
    }
  }
  
  /*
    Performs timer invalidations and variable value initialization necessary to restart dream catching process.
   Called when the start button is pressed again
 */
  func reset() {
    startButton.setTitle("START", for: .normal)
    startButton.setTitleColor(UIColor.blue, for: .normal)
    currentStatus = "IDLE"
    playedAudio = false
    falsePositive = false
    
    detectSleepTimerPause = true
    
    self.calibrateEnd()
    self.timer.invalidate()
    self.detectSleepTimer.invalidate()
    self.alarmTimer.invalidate()
    self.falsePositiveTimer.invalidate()
    self.maxTimeToFirstOnsetTimer.invalidate()
    
    self.recordingsManager.reset()
    
    if (simulationInput.isOn) {
      self.simulationTimer.invalidate()
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }
  
  func getInitParams()-> [String: String] {
    
    var ret = getParams
    
    if(areRequiredParametersSet()) {
      ret["uuidPrefix"] = uuidPrefixText?.text
      ret["calibrationTime"] = calibrationTimeText?.text
      ret["promptLatency"] = promptTimeText?.text
      ret["numberOfSleeps"] = numOnsetsText?.text
      ret["maxTimeBetweenSleeps"] = waitForOnsetTimeText?.text
      ret["falsePositiveFlexOpen"] = falsePosFlexOpenText?.text
      ret["falsePositiveFlexClosed"] = falsePosFlexClosedText?.text
      ret["minRecordingTime"] = minRecordingTimeText?.text
      ret["maxRecordingTime"] = maxRecordingTimeText?.text
      ret["deltaHBOSS"] = deltaHBOSSText?.text
      ret["deltaEDA"] = deltaEDAText?.text
      ret["deltaHRText"] = deltaHRText?.text
      ret["deltaFlexText"] = deltaFlexText?.text
      ret["maxTimeToFirstOnset"] = maxTimeToFirstOnsetText?.text
    }
    return ret
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
    
    if let val = defaults.object(forKey: "falsePosFlexOpen") {
      falsePosFlexOpenText?.text = String(val as! Int)
    }
    if let val = defaults.object(forKey: "falsePosFlexClosed") {
      falsePosFlexClosedText?.text = String(val as! Int)
    }
    if let prefix = defaults.object(forKey: "phoneUUIDPrefix") {
      uuidPrefixText?.text = prefix as! String
    }
    if let val = defaults.object(forKey: "minRecordingTime") {
      minRecordingTimeText?.text = String(val as! Int)
    }
    if let val = defaults.object(forKey: "maxRecordingTime") {
      maxRecordingTimeText?.text = String(val as! Int)
    }
    if let val = defaults.object(forKey:"maxTimeToFirstOnset") {
      maxTimeToFirstOnsetText?.text = String(val as! Int)
    }
    
    setFalsePositiveFlexParams()
    setRecordingTimes()

    var data = readDataFromCSV(fileName: "simulatedData", fileType: "csv")
    data = cleanRows(file: data!)
    self.simulatedData = csv(data: data!)
    
    getDeviceUUID()
    
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
    maxTimeToFirstOnsetText.delegate = self
  }
  
  func areRequiredParametersSet()-> Bool {
    return (calibrationTimeText?.text != "") && (promptTimeText?.text != "") && (numOnsetsText?.text != "") && (waitForOnsetTimeText?.text != "") && (falsePosFlexOpenText?.text != "") && (falsePosFlexClosedText?.text != "") && (minRecordingTimeText?.text != "") && (maxRecordingTimeText?.text != "") && (deltaEDAText?.text != "") && (deltaHRText?.text != "") && (deltaHBOSSText?.text != "")
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
    print("Is recordingManager recording in between onset speech?", recordingsManager.isRecordingSpeaking)
    if(recordingsManager.isRecordingSpeaking) {
      print("RecordingsManager is already recording, user spoke in between onsets")
      if(trigger == OnsetTrigger.TIMER) {
        print("But trigger was timer, so make sure the timer happens again")
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.waitForOnsetTimeText.text!)!, repeats: false, block: {
          t in
          self.sleepDetected(trigger: OnsetTrigger.TIMER)
        })
      }
      return
    }
    
    self.timer.invalidate()
    self.maxTimeToFirstOnsetTimer.invalidate()
    self.recordingsManager.stopSpeakingDetection()

    print("Sleep Detected, trigger was", String(describing: trigger))

    var json: [String : Any] = ["trigger" : String(describing: trigger),
                                "currDateTime" : Date().timeIntervalSince1970,
                                "deviceUUID": deviceUUID,
                                "datetime": sessionDateTime]
    
    sleepIsDetected = true
    
    flexAnalyzer.resetFalsePositive()
    
    if (!self.playedAudio) {
      self.playedAudio = true
      self.startButton.setTitle("SLEEP!", for: .normal)
      self.detectSleepTimerPause = true
      // pause timer
      
      self.falsePositiveTimer = Timer.scheduledTimer(withTimeInterval: falsePositiveTimerInterval, repeats: true, block: {
        t in
        
        if (self.flexAnalyzer.isFalsePositive()) {
          // Need to invalidate timers, delete any false-positve audio recordings, and transition back to trying to sleep
          print("False Positive Detected during sleepDetected!")
          self.falsePositiveTimer.invalidate()
          self.timer.invalidate()
          json["legitimate"] = false
          SleepAPI.apiPost(endpoint: "reportTrigger", json: json)
          self.recordingsManager.stopRecording()
          self.recordingsManager.deleteCurrentDream()
          self.recordingsManager.reset()
          self.transitionOnsetToSleep()
        }
      })
      
      self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.promptTimeText.text!)!, repeats: false, block: {
        t in
        
        self.falsePositive = false

        
        self.recordingsManager.startPlaying(mode: 1)

        self.recordingsManager.doOnPlayingEnd = { // Start of recordingsManager.doOnPlayingEnd
          self.startButton.setTitle("RECORDING", for: .normal)
          
          // silenceCallback is called from recordingsManager once silence is detected
          self.recordingsManager.startRecordingDream(dreamTitle: "Experiment", silenceCallback: { () in // Start of silenceCallback
            
            self.numOnsets += 1
            
            print("Silence Detected, or max recording time elapsed")
            self.recordingsManager.stopRecording()
            self.falsePositiveTimer.invalidate()

            json["legitimate"] = true
            SleepAPI.apiPost(endpoint: "reportTrigger", json: json)
            
            // If stil have onsets to catch, continue, else, sound alarm
            if (self.numOnsets < Int(self.numOnsetsText.text!)!) {
                self.transitionOnsetToSleep()
            } else {
                self.alarmTimer = Timer.scheduledTimer(withTimeInterval: self.waitTimeForAlarm, repeats: false, block: { (t) in
                  self.wakeupAlarm()
                })
            }
            
          }) // end of silenceCallback
        } // End of recordingsManager.doOnPlayingEnd
        
        self.calibrateStart()
        
      })
    }
  }

/*
  Called at the end of an onset to setup detection of the next onset
 */
func transitionOnsetToSleep() {
    sleepIsDetected = false
    recordingsManager.startPlayingMulti(mode: 0, numOnset: self.numOnsets)
    playedAudio = false
    startButton.setTitle("WAITING FOR SLEEP", for: .normal)
    detectSleepTimerPause = false
    calibrateEnd()
    
    self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.waitForOnsetTimeText.text!)!, repeats: false, block: {
      t in
      self.sleepDetected(trigger: OnsetTrigger.TIMER)
    })
  
    if(speakingDetectionInput.isOn){
      self.recordingsManager.startSpeakingDetectionRecording("Experiment", onSpeechCB: onNonPromptSpeech)
    }
  }

  func onNonPromptSpeech() {
    print("Speech Detected!")
    recordingsManager.startSpeakingRecording("Experiment", silenceCallback: {() in
      self.recordingsManager.stopSpeakingDetection()
      self.recordingsManager.startSpeakingDetectionRecording("Experiment", onSpeechCB: self.onNonPromptSpeech)
    })
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

/*
    Called to sound alarm and prompt user to end the session, or add more onsets, after the final onset is detected
 */
  func wakeupAlarm() {
    print("All onsets detected, sounding alarm")
    self.recordingsManager.alarm()
    let alert = UIAlertController(title: "Wakeup!", message: "Dreamcatcher has caught \(self.numOnsets) dream(s).", preferredStyle: .alert)
    
    // TODO: textfield for user to enter number of onets they would like rather than hardcode + 3
    // Asks user if they would like to continue sleeping, then increments the numOnsetsTest paramter, and transitions back to
    // detecting onsets
    alert.addAction(UIAlertAction(title: "Continue (+3 onset(s))", style: .default, handler: {action in
      if(action.style == .default) {
        print("Adding more onsets")
        self.numOnsetsText.text = String(Int(self.numOnsetsText.text!)! + 3)
        self.recordingsManager.stopAlarm()
        self.transitionOnsetToSleep()
      }
    }))
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
      if(action.style == .cancel) {
        print("Alarm Alert Dismissed")
        self.recordingsManager.stopAlarm()
        self.reset()
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
  
  func setRecordingTimes() {
    let minTime = UserDefaults.standard.object(forKey: "minRecordingTime")
    let maxTime = UserDefaults.standard.object(forKey: "maxRecordingTime")
    recordingsManager.configureRecordingTime(min: minTime, max: maxTime)
  }
  
  func setFalsePositiveFlexParams() {
    let falsePosFlexOpen = UserDefaults.standard.object(forKey: "falsePosFlexOpen")
    let falsePosFlexClosed = UserDefaults.standard.object(forKey: "falsePosFlexClosed")
    flexAnalyzer.configureFalsePositiveParams(open: falsePosFlexOpen, closed: falsePosFlexClosed)
  }
  
/*
  Displays alert providing information about the paramters in the experimental view
   Text needs to be cleaned up and formated with bolding, etc.
 */
  @IBAction func infoButtonPressed(sender: UIButton) {
    let infoString = """
DreamCatcher, with data from your Dormio, will detect when you are about to fall asleep and will play audio to guide your dream.

DreamCatcher will then prompt you to desribe your dream and will record your response.

Record A Wakeup and Sleep Message Below.

Calibration Time determines how long DreamCatcher will spend calibrating against the data from your Dormio.

Prompt Latency determines how long DreamCatcher will wait to ask you about your dream.

 Numer of Sleeps determines how many times DreamCatcher will prompt you for your dream.

 Max Time Between Sleeps determines.
"""
    let alert = UIAlertController(title: "Welcome to DreamCatcher", message: infoString, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
      if(action.style == .default) {
      }
    }))
    self.present(alert, animated: true, completion: nil)
  }

  @IBAction func waitForOnsetTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(waitForOnsetTimeText.text!), forKey: "waitForOnsetTime")
    startButton.isEnabled = areRequiredParametersSet()
  }
  @IBAction func maxOnsetsChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(numOnsetsText.text!), forKey: "numOnsets")
    startButton.isEnabled = areRequiredParametersSet()
  }
  @IBAction func promptTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(promptTimeText.text!), forKey: "promptTime")
    startButton.isEnabled = areRequiredParametersSet()
  }
  @IBAction func calibrationTimeChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(calibrationTimeText.text!), forKey: "calibrationTime")
    startButton.isEnabled = areRequiredParametersSet()
  }
  @IBAction func HBOSSChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaHBOSSText.text!), forKey: "deltaHBOSS")
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  @IBAction func flexChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaFlexText.text!), forKey: "deltaFlex")
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  @IBAction func HRChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaHRText.text!), forKey: "deltaHR")
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  @IBAction func EDAChanged(_ sender: Any) {
    UserDefaults.standard.set(Int(deltaEDAText.text!), forKey: "deltaEDA")
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  @IBAction func uuidPrefixTextChanged(_ sender: Any) {
    var uuid = getDeviceUUID()
    
    if let prefix = uuidPrefixText.text {
      setUUIDPrefix(prefix)
    }
  }
  
  @IBAction func falsePosFlexOpenTextChanged(_ sender: Any) {
    if let num = Int(falsePosFlexOpenText.text!) {
      UserDefaults.standard.set(num, forKey: "falsePosFlexOpen")
      setFalsePositiveFlexParams()
    }
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }

  @IBAction func falsePosFlexClosedTextChanged(_ sender: Any) {
    if let num = Int(falsePosFlexClosedText.text!) {
      UserDefaults.standard.set(num, forKey: "falsePosFlexClosed")
      setFalsePositiveFlexParams()
    }
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  
  @IBAction func minRecordingTimeTextChanged(_ sender: Any) {
    if let num = Int(minRecordingTimeText.text!) {
      UserDefaults.standard.set(num, forKey: "minRecordingTime")
      setRecordingTimes()
    }
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  
  @IBAction func maxRecordingTimeTextChanged(_ sender: Any) {
    if let num = Int(maxRecordingTimeText.text!) {
      UserDefaults.standard.set(num, forKey: "maxRecordingTime")
      setRecordingTimes()
    }
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  
  @IBAction func maxTimeToFirstOnsetTextChanged(_ sender: Any) {
    if let num = Int(maxTimeToFirstOnsetText.text!) {
      var maxTime = num
      if let calTime = Int(calibrationTimeText.text!) {
        maxTime = (num <= calTime) ? calTime + 1 : maxTime
        maxTimeToFirstOnsetText.text = String(maxTime)
      }
      UserDefaults.standard.set(maxTime, forKey: "maxTimeToFirstOnset")
    }
    startButton.isEnabled = areRequiredParametersSet() // check that all the paramters in experimental mode are non-empty before allowing start
  }
  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
    print("in adaptivePresentationStyleForPresentationController")
    return UIModalPresentationStyle.none
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destination.
    // Pass the selected object to the new view controller.
    
  }
  
  /*
   I embedded ViewCOntroller in a navigation controller to allow for navigation between experimental view and the
   "Remember to think of" recordings table. Used to hide the nav bar in experimental, and show the nav bar for the table view
 */
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Hide the navigation bar on the this view controller
    self.navigationController?.setNavigationBarHidden(true, animated: animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Show the navigation bar on other view controllers
    self.navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  
}
