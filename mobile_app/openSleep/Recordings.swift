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
  
  // Maps the modes (0, 1) to list of URL's. Right now, only mode 0 (Remembder to think of) recordings are stored here.
  // Wakeup prompts are still stored in audioURLs variable
  var audioMultiURLs = [Int: [URL]]()
  
  var recordingSession : AVAudioSession!
  var audioRecorder    :AVAudioRecorder!
  var audioRecorderSettings = [String : Int]()
  var audioPlayer : AVAudioPlayer!
  var alarmPlayer : AVAudioPlayer!
  var audioURLs = [Int: URL]()
  
  /*
   Paramters used for silence detection
 */
  let silencePollingTime = 0.1 // wait x seconds between checking the noise level for silence
  var dbThreshold:Float = -35.0 // threshold for silence. Value determined as minimum between this default value and calibrationSIlenceThresh
  var silenceTime = 0.0 // consecutive elapsed time with noise level below dbThreshold
  let silenceTimeThreshold = 8.0 // how much silenceTime before ending recording
  var recordingTimeElapsed = 0.0
  
  var maxRecordingTime = 120.0
  var minRecordingTime = 30.0
  
  var calibrationSilenceThresh:Float = -35.0 // determined by calibrateSilenceThreshold(), called when start/dream is pressed
  var elapsedCalTime:Float = 0.0
  let calibrationTime:Float = 10.0
  let calibrationTimeStep:Float = 0.1
  
  var silenceDetectionTimer = Timer()
  var calibrateTimer = Timer()

  var doOnPlayingEnd : (() -> ())? = nil
  
  var currentDreamRecordingURL: URL? = nil
  
  var speakingDetectionTimer = Timer()
  var speakingDetectedTime: Double = 0.0;
  let speakingDetectionMaxRecordingLength = 20
  let speakingDetectionPollingTime = 0.1
  
  var isRecordingSpeaking: Bool = false
  
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
  
  /*
    Called from RecordingsTableVIewController when cells are deleted.
 */
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
  
  /*
    Called from thinkOfRecordingsTableDelegate to handle deleting cells
 */
  func deleteThinkOfRecording(index: Int) {
    if let r = audioMultiURLs[0] {
      let url = r[index]
      
      print("Deleting ThinkOf Recording: ", r)
      audioMultiURLs[0]!.remove(at: index)
      let fileManager = FileManager.default
      do {
        try fileManager.removeItem(at: url)
      } catch {
        print("Attempting to delete file that does not exist!", url)
      }
    }
  }
  
  /*
   Called from thinkOfRecordingsTableDelegate when tableview cells are reordered
 */
  func moveAudioMultiURLs(src: Int, dst: Int) {
    if let r = audioMultiURLs[0] {
      let urlToMove = r[src]
      audioMultiURLs[0]!.remove(at: src)
      audioMultiURLs[0]!.insert(urlToMove, at: dst)
    } else {
      return
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
  
  /*
   Used for audio urls for the multiple Remember to think of recordings
 */
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
  
  /*
   Called to record multiple Remember to think of messages. Appends urls to the audioMultiUrls[0] array
 */
  func startRecordingMulti(mode: Int) {
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      if let url = self.audioDirectoryURLMulti(mode) {
        audioRecorder = try AVAudioRecorder(url: url as URL,
                                            settings: audioRecorderSettings)
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
        
        audioMultiURLs[mode]!.append(url)
        print("Multi url = \(url)")
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
  
  func startSpeakingDetectionRecording(_ dreamTitle: String, onSpeechCB: @escaping () -> ()) {
    let audioSession = AVAudioSession.sharedInstance()
    self.isRecordingSpeaking = false

    do {
      if let url = self.speakingDetectionURL() {
        audioRecorder = try AVAudioRecorder(url: url as URL, settings: audioRecorderSettings)
        print("Storing speakinddetectionRecording at", url)
        audioRecorder.isMeteringEnabled = true
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
      }
    }  catch {
      print("Error in starting audioRecorder for speakinDetection")
      audioRecorder.stop()
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
      
      self.startSpeakingDetection(dreamTitle, onSpeechCB: onSpeechCB)
    } catch {
      print("Error in starting audioRecorder for speakinDetection")
      audioRecorder.stop()
    }
    print("Finished startSpeakingDetectionRecording");
  }
  
  func startSpeakingDetection(_ dreamTitle: String, onSpeechCB: @escaping () -> ()) {
    speakingDetectionTimer = Timer.scheduledTimer(withTimeInterval: speakingDetectionPollingTime, repeats: true, block: {
      t in
      
      self.recordingTimeElapsed += self.speakingDetectionPollingTime;
      
      if(self.recordingTimeElapsed > Double(self.speakingDetectionMaxRecordingLength)) {
        self.stopSpeakingDetection()
        self.startSpeakingDetectionRecording(dreamTitle, onSpeechCB: onSpeechCB)
      }
      
      self.audioRecorder.updateMeters()
      let averagePower = self.audioRecorder.averagePower(forChannel:0)
      
      print("Power:", averagePower, "SpeakingDetectedTIme:", self.speakingDetectedTime, "total time elapsed: ", self.recordingTimeElapsed)
      
      if (averagePower > self.dbThreshold + 3) {
        self.speakingDetectedTime += self.speakingDetectionPollingTime
        self.silenceTime = 0
      } else {
        self.silenceTime += self.speakingDetectionPollingTime
      }
      if(self.silenceTime > 5.0) {
        self.speakingDetectedTime = 0.0
      }
      if(self.speakingDetectedTime > 1.0) {
        self.speakingDetectedTime = 0.0
        self.stopSpeakingDetection()
        onSpeechCB()
      }
    })
  }
  
  func startSpeakingRecording(_ dreamTitle: String, silenceCallback: @escaping () -> ()) {
    self.isRecordingSpeaking = true
    startRecordingDream(dreamTitle: dreamTitle, silenceCallback: silenceCallback)
  }
  
  func stopSpeakingDetection() {
    audioRecorder.stop()
    self.recordingTimeElapsed = 0
    self.speakingDetectedTime = 0
    self.silenceTime = 0
    isRecordingSpeaking = false
    speakingDetectionTimer.invalidate()
  }
  
  func speakingDetectionURL()-> URL? {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    return documentDirectory.appendingPathComponent("speakingDetection.m4a")
  }
  
  func startRecordingDream(dreamTitle: String, silenceCallback: @escaping () -> () ) {
    let audioSession = AVAudioSession.sharedInstance()
    let url = self.audioDirectoryURLwithTimestamp()
    
    currentDreamRecordingURL = url
    
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
        
        // + 5 to make silence detection more sensitive to noise
        // Only starts detecting silence when recordingTime elapsed is greater than minRecordingTime
        if ((averagePower < self.dbThreshold + 5) && self.recordingTimeElapsed > self.minRecordingTime) {
          self.silenceTime += self.silencePollingTime
        } else {
          self.silenceTime = 0.0
        }
        print("Silence Time: \(self.silenceTime), Time Elapsed: \(self.recordingTimeElapsed)")
        
        // if silenceTime threshold is reached or if maxrecordingtime is reached, exit
        if(((self.silenceTime > self.silenceTimeThreshold) && (self.recordingTimeElapsed > self.minRecordingTime)) || self.recordingTimeElapsed > self.maxRecordingTime) {
          self.addRecording(categoryName: dreamTitle, path: url!.absoluteString, length: Int(self.recordingTimeElapsed))
          self.resetSilenceDetection()
          print("Silent, adding recording:", url!.absoluteString)
          
          silenceCallback()
        }
      })
    } catch {
    }
  }
  
  func stopRecording() {
    print("stopping recording")
    audioRecorder.stop()
  }
  
  func deleteCurrentDream() {
    let fileManager = FileManager.default
    
    if let fileToDelete = currentDreamRecordingURL {
      print("Deleting: ", fileToDelete)
      do {
        try fileManager.removeItem(at: fileToDelete)
      } catch {
        print("Attempting to delete file that does not exist!", fileToDelete)
      }
    }
  }
  
  /*
    Resets silencedetection-related parameters
 */
  func resetSilenceDetection() {
    print("resetting silence detection")
    silenceTime = 0.0
    recordingTimeElapsed = 0.0
    silenceDetectionTimer.invalidate()
  }
  
  /*
   Starts an audio recording to use as a reference for silence. Recording continues for calibrationTime variable.
   Average power is calculated at the end of the recording session, and is stored in calibrationSilenceThresh, used in silence detection
 */
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
  
  /*
    Resets audio parameters and related timers
 */
  func reset() {
    silenceTime = 0.0
    recordingTimeElapsed = 0.0
    elapsedCalTime = 0.0
    calibrateTimer.invalidate()
    silenceDetectionTimer.invalidate()
    audioRecorder.stop()
    stopSpeakingDetection()
  }
  
  func startPlaying(mode: Int, onFinish: (() -> ())? = nil) {
    if let url = audioURLs[mode] {
      self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
      self.audioPlayer.prepareToPlay()
      self.audioPlayer.delegate = self
      //    self.audioPlayer.currentTime = max(0 as TimeInterval, self.audioPlayer.duration - audioPlaybackOffset)
      self.audioPlayer.play()
    } else {
      return
    }
  }
  
  /*
    Plays the "REmember to think of" message corresponding to numOnset. If numOnset exceeds, the recordings wrap around
 */
  func startPlayingMulti(mode: Int, numOnset: Int) {
    if let urls = audioMultiURLs[mode] {
      let numURLS = urls.count
      self.audioPlayer = try! AVAudioPlayer(contentsOf: urls[numOnset % numURLS])
      self.audioPlayer.prepareToPlay()
      self.audioPlayer.delegate = self
      self.audioPlayer.play()
    } else {
      return
    }
  }
  
  /*
   Plays the Alarm.mp3 file
 */
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
  
  func configureRecordingTime(min: Any?, max: Any?) {
    if let _min = min {
      minRecordingTime = _min as! Double
    }
    if let _max = max {
      maxRecordingTime = _max as! Double
    }
    
    print("Min \(minRecordingTime) sec recording time, Max \(maxRecordingTime) sec recording time")
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    //You can stop the audio
    player.stop()
    if let dope = doOnPlayingEnd {
      dope()
      doOnPlayingEnd = nil
    }
  }
  
  /*
   Called from thinkOfRecordingsTableDelegate to obtain recording urls for playing, deletion, reordering
 */
  func getThinkOfRecordings(mode: Int, index: Int)-> URL? {
    if index < audioMultiURLs[mode]!.count {
      return audioMultiURLs[mode]![index]
    } else {
      return nil
    }
  }
}


