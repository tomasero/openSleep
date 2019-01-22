//
//  ThinkOfRecordingTableViewController.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/20/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import UIKit
import AVFoundation

class ThinkOfRecordingTableViewController: thinkOfRecordingsTableDelegate {
  
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var height: NSLayoutConstraint!
  @IBOutlet weak var width: NSLayoutConstraint!

  var isRecording: Bool = false
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      tableView.dataSource = self
      tableView.delegate = self
      let screenSize = UIScreen.main.bounds
      height.constant = screenSize.height * 0.65
      width.constant = screenSize.width
    }

  
  @IBAction func startEditing(_ sender: Any) {
    tableView.isEditing = !tableView.isEditing
    let b = sender as! UIBarButtonItem
    b.title = (b.title == "Edit") ? "Done" : "Edit"
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

}
