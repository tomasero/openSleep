//
//  ThinkOfRecordingTableViewController.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/20/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import UIKit

class ThinkOfRecordingTableViewController: UIViewController, UITableViewDataSource {
  
  
  @IBOutlet weak var tableView: UITableView!
  var recordingsManager = RecordingsManager.shared
  
  var isRecording: Bool = false
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      tableView.dataSource = self
    }

  func numberOfSections(in tableView: UITableView) -> Int {
    print("numberOfSections called")
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
    print("cellForRowAt called")
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
