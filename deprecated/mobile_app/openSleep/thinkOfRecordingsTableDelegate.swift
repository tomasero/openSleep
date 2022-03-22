//
//  thinkOfRecordingsTableDelegate.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/21/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/*
  Provides delegate function defintions for UITableView, used to list and interact with "Record Think Of" recordings
 */
class thinkOfRecordingsTableDelegate: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate {
  
  var recordingsManager = RecordingsManager.shared
  
  var audioPlayer : AVAudioPlayer!
  
  var indexOfRowPlaying: IndexPath?
  
  var tV: UITableView!
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let urls = recordingsManager.audioMultiURLs[0] {
      return urls.count
    }
    else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "thinkOfRecordingCell", for: indexPath) as! ThinkOfRecordingCell
    cell.label?.text = "Remember To Think Of (\(indexPath.row))"
    
    func secondsToMinutesSeconds (seconds:Int) -> String {
      let m = (seconds % 3600) / 60
      let s = (seconds % 3600) % 60
      return String(format: "%02d:%02d", m, s)
    }
    
    if let rec_url = recordingsManager.getThinkOfRecordings(mode: 0, index: indexPath.row) {
      print(rec_url)
    }
    return cell
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if self.tV == nil {
      self.tV = tableView
    }
    
    if let playingIndexRow = self.indexOfRowPlaying {
      print("self.indexOfRowPlaying is not nil")
      self.audioPlayer.stop()
      tableView.deselectRow(at: playingIndexRow, animated: true)
      self.indexOfRowPlaying = nil
      if playingIndexRow == indexPath {
        return
      }
    }
    if let recording_url = recordingsManager.getThinkOfRecordings(mode:0, index: indexPath.row) {
      print("Playing \(recording_url)")
      do {
        self.audioPlayer = try AVAudioPlayer(contentsOf: recording_url)
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.delegate = self
        self.audioPlayer.play()
        self.indexOfRowPlaying = indexPath
      } catch {
        Alert(self, "Unable to locate audio file!")
        tableView.deselectRow(at: indexPath, animated: true)
        self.indexOfRowPlaying = nil
      }
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    player.stop()
    tV.deselectRow(at: self.indexOfRowPlaying!, animated: true)
    self.indexOfRowPlaying = nil
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    recordingsManager.moveAudioMultiURLs(src: sourceIndexPath.row, dst: destinationIndexPath.row)
    tableView.reloadData()
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      //Delete the row from the data source
      recordingsManager.deleteThinkOfRecording(index: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return true
  }
}
