//
//  ThinkOfRecordingTableViewController.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/20/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import UIKit
import AVFoundation

class ThinkOfRecordingTableViewController: UIViewController, UITableViewDataSource, AVAudioPlayerDelegate, UITableViewDelegate {
  
  
  @IBOutlet weak var tableView: UITableView!
  var recordingsManager = RecordingsManager.shared

  var audioPlayer : AVAudioPlayer!

  var isRecording: Bool = false
  var indexOfRowPlaying: IndexPath?
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      tableView.dataSource = self
      tableView.delegate = self
    }

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
  
  @IBAction func recordButtonPressed(_ sender: UIButton) {
    if !isRecording {
      sender.setTitle("Stop", for: .normal)
      sender.setTitleColor(UIColor.red, for: .normal)
      isRecording = true
      recordingsManager.startRecordingMulti(mode: 0)
    } else {
      sender.setTitle("Record \"You can fall asleep now, Remember to think of...\"", for: .normal)
      sender.setTitleColor(UIColor.blue, for: .normal)
      isRecording = false
      recordingsManager.stopRecording()
      tableView.reloadData()
    }
  }

  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let playingIndexRow = self.indexOfRowPlaying {
      print("self.indexOfRowPlaying is not nil")
      self.audioPlayer.stop()
      self.tableView.deselectRow(at: playingIndexRow, animated: true)
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
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.indexOfRowPlaying = nil
      }
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    //You can stop the audio
    player.stop()
    self.tableView.deselectRow(at: self.indexOfRowPlaying!, animated: true)
    self.indexOfRowPlaying = nil
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    recordingsManager.moveAudioMultiURLs(src: sourceIndexPath.row, dst: destinationIndexPath.row)
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      //Delete the row from the data source
      recordingsManager.deleteThinkOfRecording(index: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }
  

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
