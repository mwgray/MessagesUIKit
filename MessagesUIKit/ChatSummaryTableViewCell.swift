//
//  ChatSummaryTableViewCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 9/15/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import UIKit
import MessagesKit


public class ChatSummaryTableViewCell: UITableViewCell {
  
  
  @IBOutlet var senderLabel : UILabel!
  @IBOutlet var dateLabel : UILabel!
  @IBOutlet var summaryLabel : UILabel!
  @IBOutlet var summaryLabelRight : NSLayoutConstraint!
  @IBOutlet var summaryLabelLeft : NSLayoutConstraint!
  @IBOutlet var notificationDotView : UIView!
  
  var title : ChatTitle?
  
}
