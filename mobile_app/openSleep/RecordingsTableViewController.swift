//
//  RecordingsTableViewController.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 11/21/18.
//  Copyright © 2018 Tomas Vega. All rights reserved.
//


import UIKit
import AVFoundation

class RecordingsTableViewController: UITableViewController, AVAudioPlayerDelegate {
  
  var audioPlayer : AVAudioPlayer!
  var isPlaying : IndexPath? = nil
  var recordingsManager = RecordingsManager.shared
  var documentInteractionController: UIDocumentInteractionController!

  override func viewDidLoad() {
      super.viewDidLoad()

      // Uncomment the following line to preserve selection between presentations
      // self.clearsSelectionOnViewWillAppear = false

      // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
      // self.navigationItem.rightBarButtonItem = self.editButtonItem
    
    setupLongPress()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tableView.reloadData()
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
      // #warning Incomplete implementation, return the number of sections
      return recordingsManager.numOfCategories()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return recordingsManager.numOfRecordings(category: section)
  }

  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)

    let formatter = DateFormatter()
    // initially set the format based on your datepicker date / server String
    formatter.dateFormat = "dd/MM HH:mm"
    
    func secondsToMinutesSeconds (seconds:Int) -> String {
      let m = (seconds % 3600) / 60
      let s = (seconds % 3600) % 60
      return String(format: "%02d:%02d", m, s)
    }
    
    if let recording = recordingsManager.getRecording(category: indexPath.section, index: indexPath.row) {
      cell.textLabel?.text = formatter.string(from: recording.time)
      cell.detailTextLabel?.text = secondsToMinutesSeconds(seconds: recording.length)
    }

    return cell
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return recordingsManager.getCategoryTitle(category: section)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //code to execute on click
    if let playingIndexRow = self.isPlaying {
      self.audioPlayer.stop()
      self.tableView.deselectRow(at: playingIndexRow, animated: true)
      self.isPlaying = nil
      if playingIndexRow == indexPath {
        return
      }
    }
    if let recording = recordingsManager.getRecording(category: indexPath.section, index: indexPath.row) {
      print("Playing \(recording.path)")
      do {
        self.audioPlayer = try AVAudioPlayer(contentsOf: URL(string: recording.path)!)
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.delegate = self
        self.audioPlayer.play()
        self.isPlaying = indexPath
      } catch {
        Alert(self, "Unable to locate audio file!")
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.isPlaying = nil
      }
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    //You can stop the audio
    player.stop()
    self.tableView.deselectRow(at: self.isPlaying!, animated: true)
    self.isPlaying = nil
  }
  

  /*
  // Override to support conditional editing of the table view.
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
      // Return false if you do not want the specified item to be editable.
      return true
  }
  */

   /*
   Deletes a row. Calls deleteReocrding of recordingsManager to remove that audio recording from storage
 */
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
      if editingStyle == .delete {
           //Delete the row from the data source
            recordingsManager.deleteRecording(category: indexPath.section, index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
      }
  }
  
  /*
   Called to bring up ui to share/send a particulat audio recording
   */
  func share(urlString:String, touchPoint: CGRect) {
    let url = URL(string: urlString)!
    documentInteractionController = UIDocumentInteractionController()
    documentInteractionController.url = url
    documentInteractionController.uti = url.uti
    documentInteractionController.presentOptionsMenu(from: touchPoint, in: self.view, animated: true)
  }
  
  /*
   copypasta from stack overflow (Sazzad Hissain Khan's answer on https://stackoverflow.com/questions/30839275/how-to-select-a-table-row-during-a-long-press-in-swift
   */
  func setupLongPress() {
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
    self.view.addGestureRecognizer(longPressRecognizer)
  }
  
  /*
   On a long press, call share to allow user to send/share the audio recording associated with the cell
   copypasta from stack overflow (Sazzad Hissain Khan's answer on https://stackoverflow.com/questions/30839275/how-to-select-a-table-row-during-a-long-press-in-swift
   */
  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    
    if sender.state == UIGestureRecognizerState.began {
      let touchPoint = sender.location(in: self.view)
      if let indexPath = tableView.indexPathForRow(at: touchPoint) {
        if let recording = recordingsManager.getRecording(category: indexPath.section, index: indexPath.row) {
          print("Long pressed row: \(recording.path)")
          let recSize = CGSize(width: 10, height: 10)
          let rec = CGRect(origin: touchPoint, size: recSize)
          self.share(urlString: recording.path, touchPoint: rec)
        }
      }
    }
  }

  /*
  // Override to support rearranging the table view.
  override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

  }
  */

  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
      // Return false if you do not want the item to be re-orderable.
      return true
  }
  */

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destination.
      // Pass the selected object to the new view controller.
  }
  */

}

extension URL {
  var uti: String {
    return (try? self.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier ?? "public.data"
  }
  
}
