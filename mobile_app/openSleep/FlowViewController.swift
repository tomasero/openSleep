//
//  FlowViewController.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/25/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class FlowViewController:
  UIViewController,
  DormioDelegate,
  UITextFieldDelegate {

  // Singletons
  var flowManager = FlowManager.shared
  var dormioManager = DormioManager.shared
  var recordingsManager = RecordingsManager.shared
  var activeView : Int = -1
  
  var player : AVPlayer?

  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var connectButton: UIButton!
  @IBOutlet weak var dreamText: UITextField!
  @IBOutlet weak var continue1Button: UIButton!
  @IBOutlet weak var continue2Button: UIButton!
  @IBOutlet weak var continue3Button: UIButton!
  @IBOutlet weak var dreamButton: UIButton!
  @IBOutlet weak var dreamStageControl: UISegmentedControl!
  @IBOutlet weak var dreamLabel: UILabel!
  @IBOutlet weak var EDALabel: UILabel!
  @IBOutlet weak var HRLabel: UILabel!
  @IBOutlet weak var flexLabel: UILabel!
  
  @IBOutlet weak var numOnsetsControl: UISegmentedControl!
  @IBOutlet weak var sleepMessageLabel: UILabel!
  @IBOutlet weak var microphoneImage: UIImageView!
  @IBOutlet weak var dreamDetectorControl: UISegmentedControl!
  
  var autoCompleteCharacterCount = 0
  var autoCompleteTimer = Timer()
  
  var playedAudio : Bool = false
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
  
  var isRecording = false
  var timer = Timer()
  
  var uuids = ID()
  
  override func viewDidLoad() {
      super.viewDidLoad()
    
    if connectButton != nil {
      activeView = 0
      playVideo()
    }
    if let cb = continue1Button {
      cb.isEnabled = false
      cb.setTitleColor(UIColor.lightGray, for: .disabled)
      activeView = 1
    }
    if let cb = continue2Button {
      cb.isEnabled = false
      cb.setTitleColor(UIColor.lightGray, for: .disabled)
      activeView = 2
    }
    if let cb = continue3Button {
      cb.isEnabled = false
      cb.setTitleColor(UIColor.lightGray, for: .disabled)
      activeView = 3
    }
    if let dsc = dreamStageControl {
      print("AAA")
      flowManager.dreamStage = dsc.selectedSegmentIndex
      activeView = 4
    }
    if let noc = numOnsetsControl {
      flowManager.numOnsets = noc.selectedSegmentIndex + 1
      activeView = 5
    }
    if dreamButton != nil {
      dormioManager.delegate = self
      activeView = 6
      microphoneImage.isHidden = true
      HRLabel.text = ""
      EDALabel.text = ""
      flexLabel.text = ""
    }

      // Do any additional setup after loading the view.
  }
  
  private func playVideo() {
    guard let path = Bundle.main.path(forResource: "dormio", ofType:"m4v") else {
      debugPrint("dormio.m4v not found")
      return
    }
    player = AVPlayer(url: URL(fileURLWithPath: path))
    player?.volume = 0
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = self.view.bounds
    self.view.backgroundColor = UIColor.clear;
    self.view.layer.insertSublayer(playerLayer, at: 0)
    player?.play()
    
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
      self.player?.seek(to: kCMTimeZero)
      self.player?.play()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    if let sml = sleepMessageLabel {
      sml.text = "\"You can fall asleep now,\nRemember to think of " + flowManager.dreamTitle! + "\""
    }
  }
  
  @IBAction func numOnsetsChanged(_ sender: Any) {
    flowManager.numOnsets = numOnsetsControl.selectedSegmentIndex + 1
  }
  
  @IBAction func dreamStageChanged(_ sender: Any) {
    flowManager.dreamStage = dreamStageControl.selectedSegmentIndex
  }
  
  @IBAction func timersPressed(_ sender: Any) {
    // TODO: set timer mode
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let newViewController = storyBoard.instantiateViewController(withIdentifier: "step2") as! FlowViewController
    self.navigationController?.pushViewController(newViewController, animated: true)
  }
  
  @IBAction func connectPressed(_ sender: Any) {
    dormioManager.delegate = self
    if dormioManager.isConnected {
      dormioManager.disconnect()
    } else {
      dormioManager.scanAndConnect()
      self.connectButton.setTitle("Scanning...", for: .normal)
      
    }
  }
  
  @IBAction func recordWakupPressed(_ sender: UIButton) {
    continue2Button.isEnabled = true
    if !isRecording {
      recordingsManager.startRecording(mode: 1)
      sender.isSelected = true
    } else {
      recordingsManager.stopRecording()
      sender.isSelected = false
    }
    isRecording = !isRecording
  }
  
  @IBAction func recordSleepPressed(_ sender: UIButton) {
    continue3Button.isEnabled = true
    if !isRecording {
      recordingsManager.startRecording(mode: 0)
      sender.isSelected = true
    } else {
      recordingsManager.stopRecording()
      sender.isSelected = false
    }
    isRecording = !isRecording
    
  }
  @IBAction func continue1Pressed(_ sender: Any) {
    flowManager.dreamTitle = self.dreamText.text
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let newViewController = storyBoard.instantiateViewController(withIdentifier: "step3") as! FlowViewController
    self.navigationController?.pushViewController(newViewController, animated: true)
  }
  
  @IBAction func continuePressed(_ sender: UIButton) {
    if isRecording {
      recordingsManager.stopRecording()
    }
    print("Moving to step " + String(activeView + 2))
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let newViewController = storyBoard.instantiateViewController(withIdentifier: "step" + String(activeView + 2)) as! FlowViewController
    self.navigationController?.pushViewController(newViewController, animated: true)
  }
  
  @IBAction func dreamPressed(_ sender: Any) {
    if (currentStatus == "IDLE") {
      dreamButton.setTitle("Cancel", for: .normal)
      dreamButton.setTitleColor(UIColor.red, for: .normal)
      dreamLabel.text = "Enjoy your dreams :)"
      currentStatus = "CALIBRATING"
      
      uuids.newSessionId()
      print("Device ID", uuids.deviceID, "session id", uuids.sessionID)
      
      self.detectSleepTimer.invalidate()
      
      SleepAPI.apiGet(endpoint: "init")
      self.calibrateStart()
      self.numOnsets = 0
      
      self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {
        t in
        self.recordingsManager.startPlaying(mode: 0)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(UserDefaults.standard.object(forKey: "calibrationTime") as! Int) - 30, repeats: false, block: {
          t in
          self.currentStatus = "RUNNING"
          self.calibrateEnd()
          
          SleepAPI.apiGet(endpoint: "train")
          
          self.detectSleepTimerPause = false
          self.detectSleepTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.detectSleep(sender:)), userInfo: nil, repeats: true)
        })
      })
      
      
    } else if (currentStatus == "CALIBRATING" || currentStatus == "RUNNING") {
      dreamButton.setTitle("Dream", for: .normal)
      dreamButton.setTitleColor(UIColor.blue, for: .normal)
      dreamLabel.text = "Relax for 30 seconds.\nWhen your bio-signals stabilize, press Dream"
      currentStatus = "IDLE"
      self.calibrateEnd()
      
      self.timer.invalidate()
      self.detectSleepTimer.invalidate()
    }
  }
  
  @objc func detectSleep(sender: Timer) {
    SleepAPI.apiGet(endpoint: "predict", onSuccess: { json in
      let score = Int((json["max_sleep"] as! NSNumber).floatValue.rounded())
      if (!self.detectSleepTimerPause && self.numOnsets == 0) {
        if (self.dreamDetectorControl.selectedSegmentIndex == 0 && score >= (UserDefaults.standard.object(forKey: "deltaHBOSS") as! Int)) {
          DispatchQueue.main.async {
            self.sleepDetected()
          }
        } else if (self.dreamDetectorControl.selectedSegmentIndex == 1 && abs(self.lastHR - self.meanHR) >= (UserDefaults.standard.object(forKey: "deltaHR") as! Int)) {
          DispatchQueue.main.async {
            self.sleepDetected()
          }
        } else if (self.dreamDetectorControl.selectedSegmentIndex == 2 && abs(self.lastEDA - self.meanEDA) >= (UserDefaults.standard.object(forKey: "deltaEDA") as! Int)) {
          DispatchQueue.main.async {
            self.sleepDetected()
          }
        } else if (self.dreamDetectorControl.selectedSegmentIndex == 3 && abs(self.lastFlex - self.meanFlex) >= (UserDefaults.standard.object(forKey: "deltaFlex") as! Int)) {
          DispatchQueue.main.async {
            self.sleepDetected()
          }
        }
      }
    })
  }
  
  func sleepDetected() {
    self.timer.invalidate()
    print("Sleep!")
    if (!self.playedAudio) {
      self.playedAudio = true
      self.detectSleepTimerPause = true
      // pause timer
      self.timer = Timer.scheduledTimer(withTimeInterval: flowManager.promptTimeDelay(), repeats: false, block: {
        t in
        self.recordingsManager.startPlaying(mode: 1)
        self.numOnsets += 1
        self.recordingsManager.doOnPlayingEnd = {
          self.microphoneImage.isHidden = false
          self.recordingsManager.startRecordingDream(dreamTitle: self.flowManager.dreamTitle!)
        }
        self.calibrateStart()
        if (self.numOnsets < self.flowManager.numOnsets) {
          self.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: {
            t in
            self.recordingsManager.stopRecording()
            self.recordingsManager.startPlaying(mode: 0)
            self.microphoneImage.isHidden = true
            self.playedAudio = false
            self.detectSleepTimerPause = false
            self.calibrateEnd()
            
            
            self.timer = Timer.scheduledTimer(withTimeInterval: Double(UserDefaults.standard.object(forKey: "waitForOnsetTime") as! Int), repeats: false, block: {
              t in
              self.sleepDetected()
            })
          })
        }
      })
    }
  }
  
  func dormioConnected() {
    print("Connected")
    self.connectButton.setTitle("Disconnect Dormio", for: .normal)
    if activeView == 0 {
      let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
      let newViewController = storyBoard.instantiateViewController(withIdentifier: "step2") as! FlowViewController
      self.navigationController?.pushViewController(newViewController, animated: true)
    }
  }
  
  func dormioDisconnected() {
    self.connectButton.setTitle("Connect Dormio", for: .normal)
  }
  
  func dormioData(hr: UInt32, eda: UInt32, flex: UInt32) {
    if activeView == 6 {
      flexLabel.text = String(flex);
      EDALabel.text = String(eda);
      hrQueue.put(hr: hr)
      if (Date().timeIntervalSince1970 - lastHrUpdate > 1) {
      lastHrUpdate = Date().timeIntervalSince1970
      HRLabel.text = String(hrQueue.bpm())
      }

      if (self.currentStatus != "IDLE") {
        sendData(flex: flex, hr: hr, eda: eda)
      }

      if (self.isCalibrating) {
        calibrateData(flex: flex, hr: hrQueue.bpm(), eda: eda)
      }
    }
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
                                  "deviceUUID": uuids.deviceID,
                                  "sessionUUID": uuids.sessionID]
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
    }
  }
  
  
  // AUTOCOMPLETE
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { //1
    continue1Button.isEnabled = true
    
    var subString = (textField.text!.capitalized as NSString).replacingCharacters(in: range, with: string) // 2
    subString = formatSubstring(subString: subString)
    
    if subString.count == 0 { // 3 when a user clears the textField
      resetValues()
    } else {
      searchAutocompleteEntriesWIthSubstring(substring: subString) //4
    }
    return true
  }
  
  func formatSubstring(subString: String) -> String {
    let formatted = String(subString.dropLast(autoCompleteCharacterCount)).lowercased().capitalized //5
    return formatted
  }
  
  func resetValues() {
    autoCompleteCharacterCount = 0
    dreamText.text = ""
    continue1Button.isEnabled = false
  }
  
  func searchAutocompleteEntriesWIthSubstring(substring: String) {
    let userQuery = substring
    let suggestions = getAutocompleteSuggestions(userText: substring) //1
    
    if suggestions.count > 0 {
      autoCompleteTimer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //2
        let autocompleteResult = self.formatAutocompleteResult(substring: substring, possibleMatches: suggestions) // 3
        self.putColourFormattedTextInTextField(autocompleteResult: autocompleteResult, userQuery : userQuery) //4
        self.moveCaretToEndOfUserQueryPosition(userQuery: userQuery) //5
      })
    } else {
      autoCompleteTimer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //7
        self.dreamText.text = substring
      })
      autoCompleteCharacterCount = 0
    }
  }
  
  func getAutocompleteSuggestions(userText: String) -> [String]{
    var possibleMatches: [String] = []
    for item in recordingsManager.getCategories() { //2
      let myString:NSString! = item as NSString
      let substringRange :NSRange! = myString.range(of: userText)
      
      if (substringRange.location == 0)
      {
        possibleMatches.append(item)
      }
    }
    return possibleMatches
  }
  
  func putColourFormattedTextInTextField(autocompleteResult: String, userQuery : String) {
    let colouredString: NSMutableAttributedString = NSMutableAttributedString(string: userQuery + autocompleteResult)
    colouredString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.gray, range: NSRange(location: userQuery.count,length:autocompleteResult.count))
    self.dreamText.attributedText = colouredString
  }
  func moveCaretToEndOfUserQueryPosition(userQuery : String) {
    if let newPosition = self.dreamText.position(from: self.dreamText.beginningOfDocument, offset: userQuery.count) {
      self.dreamText.selectedTextRange = self.dreamText.textRange(from: newPosition, to: newPosition)
    }
    let selectedRange: UITextRange? = dreamText.selectedTextRange
    dreamText.offset(from: dreamText.beginningOfDocument, to: (selectedRange?.start)!)
  }
  func formatAutocompleteResult(substring: String, possibleMatches: [String]) -> String {
    var autoCompleteResult = possibleMatches[0]
    autoCompleteResult.removeSubrange(autoCompleteResult.startIndex..<autoCompleteResult.index(autoCompleteResult.startIndex, offsetBy: substring.count))
    autoCompleteCharacterCount = autoCompleteResult.count
    return autoCompleteResult
  }
  // END AUTOCOMPLETE
 
  
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
