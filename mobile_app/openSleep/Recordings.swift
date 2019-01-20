//
//  Recordings.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/21/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//

import Foundation
import AVFoundation

struct Recording : Codable {
  var path: String
  var time: Date
  var length: Int
}

class RecordingsManager : NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
  static let shared = RecordingsManager()
  
  
  var recordings = [String : [Recording]]()
  
  var audioMultiURLs = [Int: [URL]]()
  var recordingSession : AVAudioSession!
  var audioRecorder    :AVAudioRecorder!
  var audioRecorderSettings = [String : Int]()
  var audioPlayer : AVAudioPlayer!
  var alarmPlayer : AVAudioPlayer!
  var audioURLs = [Int: URL]()
  
  let silencePollingTime = 0.1
  var dbThreshold:Float = -35.0
  var silenceTime = 0.0
  let silenceTimeThreshold = 8.0
  var recordingTimeElapsed = 0.0
  let maxRecordingTime = 120.0
  let minRecordingTime = 30.0
  
  var calibrationSilenceThresh:Float = -35.0
  var elapsedCalTime:Float = 0.0
  let calibrationTime:Float = 10.0
  let calibrationTimeStep:Float = 0.1

  var doOnPlayingEnd : (() -> ())? = nil
  
  var silenceDetectionTimer = Timer()
  var calibrateTimer = Timer()
  private override init() {
    super.init()
    
    let defaults = UserDefaults.standard
    if let savedPerson = defaults.object(forKey: "recordings") as? Data {
      let decoder = JSONDecoder()
      if let loadedRecordings = try? decoder.decode(Dictionary<String, Array<Recording>>.self, from: savedPerson) {
        recordings = loadedRecordings
      }
    }
    
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
    
    audioMultiURLs[0] = []
    audioMultiURLs[1] = []
  }
  
  func addRecording(categoryName: String, path: String, length: Int) {
    let newRecording = Recording(path: path, time: Date(), length: length)
    if var r = recordings[categoryName] {
      r.append(newRecording)
      recordings[categoryName] = r
    } else {
      recordings[categoryName] = [newRecording]
    }
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(recordings) {
      let defaults = UserDefaults.standard
      defaults.set(encoded, forKey: "recordings")
    }
  }
  
  func numOfCategories() -> Int {
    return recordings.count
  }
  
  func numOfRecordings(category: Int) -> Int {
    let key = Array(recordings.keys)[category]
    if let r = recordings[key] {
      return r.count
    }
    return 0
  }
  
  func getCategories() -> [String] {
    return Array(recordings.keys)
  }
  
  func getRecording(category: Int, index: Int) -> Recording? {
    let key = Array(recordings.keys)[category]
    if let r = recordings[key] {
      return r[index]
    }
    return nil
  }
  
  func deleteRecording(category: Int, index: Int) {
    
    let key = Array(recordings.keys)[category]
    if let r = recordings[key] {
      let rec = r[index]
      print("Deleting recording" ,(URL(string: rec.path))!)
      
      recordings[key]?.remove(at: index)
      
      let fileManager = FileManager.default
      
      let fileToDelete = URL(string: rec.path)!
      do {
        try fileManager.removeItem(at: fileToDelete)
      } catch {
        print("Attempting to delete file that does not exist!", fileToDelete)
      }
    }
    
  }
  
  func getCategoryTitle(category: Int) -> String? {
    let key = Array(recordings.keys)[category]
    return key
  }
  
  func audioDirectoryURL(_ number: Int) -> URL? {
    let id: String = String(number)
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let soundURL = documentDirectory.appendingPathComponent("sound_\(id).m4a")
    print(soundURL!)
    return soundURL
  }
  
  func audioDirectoryURLwithTimestamp() -> URL? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmm:ss"
    let now = formatter.string(from: Date())
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let soundURL = documentDirectory.appendingPathComponent("record_\(now).m4a")
    print(soundURL!)
    return soundURL
  }
  
  func audioDirectoryURLMulti(_ mode: Int) -> URL? {
    let id: String = String(mode)
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let soundURL = documentDirectory.appendingPathComponent("sound_\(id)_\(audioMultiURLs[mode]!.count).m4a")
    print(soundURL!)
    return soundURL
  }
  
  // mode - 0: think of, 1: what are you dreamin
  func startRecording(mode: Int) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      if let url = self.audioDirectoryURL(mode) {
        //addRecording(categoryName: "Test", path: url!.absoluteString, length: 60)
        audioRecorder = try AVAudioRecorder(url: url as URL,
                                            settings: audioRecorderSettings)
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
        
        audioURLs[mode] = url
        print("url = \(url)")
      }
    } catch {
      audioRecorder.stop()
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
    } catch {
    }
  }
  
  
  // mode - 0: think of, 1: what are you dreaming
  func startRecordingMulti(mode: Int) {
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      if let url = self.audioDirectoryURLMulti(mode) {
        audioRecorder = try AVAudioRecorder(url: url as URL,
                                            settings: audioRecorderSettings)
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
        
        audioMultiURLs[mode]!.append(url)
      }
    }  catch {
      audioRecorder.stop()
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
    } catch {
    }
  }
  
  func startRecordingDream(dreamTitle: String, silenceCallback: @escaping () -> () ) {
    let audioSession = AVAudioSession.sharedInstance()
    print("CURRENT DATE IS", Date())
    let url = self.audioDirectoryURLwithTimestamp()
    do {
      if url != nil {
        audioRecorder = try AVAudioRecorder(url: url! as URL,
                                            settings: audioRecorderSettings)
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        print("URL IS = \(url!)")
      }
    } catch {
      audioRecorder.stop()
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
      
      self.dbThreshold = (self.dbThreshold < self.calibrationSilenceThresh) ? self.dbThreshold : self.calibrationSilenceThresh
      print("dbThreshold is:", self.dbThreshold)
      
      silenceDetectionTimer = Timer.scheduledTimer(withTimeInterval: silencePollingTime, repeats: true, block: { (timer: Timer) in
        
        self.audioRecorder.updateMeters()
        let averagePower = self.audioRecorder.averagePower(forChannel:0)
        self.recordingTimeElapsed += self.silencePollingTime
        if ((averagePower < self.dbThreshold + 5) && self.recordingTimeElapsed > self.minRecordingTime) {
          self.silenceTime += self.silencePollingTime
        } else {
          self.silenceTime = 0.0
        }
//        print("Silence Time: \(self.silenceTime), Time Elapsed: \(self.recordingTimeElapsed)")
        if(((self.silenceTime > self.silenceTimeThreshold) && (self.recordingTimeElapsed > self.minRecordingTime)) || self.recordingTimeElapsed > self.maxRecordingTime) {
          self.addRecording(categoryName: dreamTitle, path: url!.absoluteString, length: Int(self.recordingTimeElapsed))
          self.resetSilenceDetection()
          print("SILENT, ADDING RECORDING", url!.absoluteString)
          let cb = silenceCallback
          cb()
        }
      })
    } catch {
    }
  }
  
  func stopRecording() {
    print("stopping recording")
    audioRecorder.stop()
  }
  
  func stopRecordingMulti(mode: Int) {
    
  }
  
  func resetSilenceDetection() {
    print("resetting silence detection")
    self.silenceTime = 0.0
    self.recordingTimeElapsed = 0.0
    self.silenceDetectionTimer.invalidate()
  }
  
  func stopRecordingAndSilenceDetection() {
    stopRecording()
    self.resetSilenceDetection()
  }
  
  func calibrateSilenceThreshold() {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let url = documentDirectory.appendingPathComponent("calibrateSilentThreshold.m4a")!
    
    do {
    audioRecorder = try AVAudioRecorder(url: url as URL,
                                        settings: audioRecorderSettings)
    audioRecorder.delegate = self
    audioRecorder.isMeteringEnabled = true
    audioRecorder.prepareToRecord()
      
    } catch {
      audioRecorder.stop()
    }
    audioRecorder.record()
    
    var runningSum:Float = 0.0
    
    calibrateTimer = Timer.scheduledTimer(withTimeInterval: Double(self.calibrationTimeStep), repeats: true, block: { (timer: Timer) in
      if(self.elapsedCalTime > self.calibrationTime) {
        timer.invalidate()
        self.audioRecorder.stop()
        self.calibrationSilenceThresh = Float(runningSum / (self.calibrationTime / self.calibrationTimeStep))
        print("CALIBRATION SILENCE THRESH IS", self.calibrationSilenceThresh)
        self.elapsedCalTime = 0.0
      } else {
        self.elapsedCalTime += 0.1
        self.audioRecorder.updateMeters()
        runningSum += self.audioRecorder.averagePower(forChannel: 0)
      }
    })
    
  }
  
  func reset() {
    silenceTime = 0.0
    recordingTimeElapsed = 0.0
    elapsedCalTime = 0.0
    calibrateTimer.invalidate()
    silenceDetectionTimer.invalidate()
    audioRecorder.stop()
  }
  
  func startPlaying(mode: Int, onFinish: (() -> ())? = nil) {
    self.audioPlayer = try! AVAudioPlayer(contentsOf: audioURLs[mode]!)
    self.audioPlayer.prepareToPlay()
    self.audioPlayer.delegate = self
    //    self.audioPlayer.currentTime = max(0 as TimeInterval, self.audioPlayer.duration - audioPlaybackOffset)
    self.audioPlayer.play()
  }
  
  func alarm() {
    let alarmURL = URL(string: Bundle.main.path(forResource: "Alarm", ofType: "mp3")!)
    self.alarmPlayer = try! AVAudioPlayer(contentsOf: alarmURL!)
    self.alarmPlayer.prepareToPlay()
    self.alarmPlayer.delegate = self
    self.alarmPlayer.numberOfLoops = -1
    self.alarmPlayer.play()
  }
  func stopAlarm() {
    self.alarmPlayer.stop()
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    //You can stop the audio
    player.stop()
    if let dope = doOnPlayingEnd {
      dope()
      doOnPlayingEnd = nil
    }
  }
  
  func getThinkOfRecordings(mode: Int, index: Int)-> URL? {
    if index < audioMultiURLs[mode]!.count {
      return audioMultiURLs[mode]![index]
    } else {
      return nil
    }
  }
}


