//
//  ThinkOfRecordingCell.swift
//  openSleep
//
//  Created by Adam Haar Horowitz on 1/20/19.
//  Copyright © 2019 Tomas Vega. All rights reserved.
//

import UIKit

class ThinkOfRecordingCell: UITableViewCell {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var durationLabel: UILabel!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
