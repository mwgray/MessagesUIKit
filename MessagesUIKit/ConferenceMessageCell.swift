//
//  ConferenceMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


class ConferenceMessageCell : MessageCell {
  
  let DeclinedMessage = "You declined the request"
  
  @IBOutlet var greetingLabel : UILabel!
  @IBOutlet var buttonsLayoutView : UIView!
  @IBOutlet var phoneIcon : UIImageView!
  
  var conferenceMessage : ConferenceMessage!
  
  override func updateWithMessage(message: Message) {
    super.updateWithMessage(message)
    
    conferenceMessage = message as! ConferenceMessage
    
    var phoneIconColor = UIColor.blackColor()
    
    switch (conferenceMessage.conferenceStatus) {
      
    case .Completed, .InProgress:
      
      if conferenceMessage.localAction == .Declined {
        greetingLabel.text = conferenceMessage.summaryText()
        buttonsLayoutView.hidden = conferenceMessage.sentByMe
      }
      else {
        greetingLabel.text = DeclinedMessage
        buttonsLayoutView.hidden = true
      }
      
      break
      
    case .Missed:
      
      phoneIconColor = message.sentByMe ? phoneIconColor : UIColor.redColor()
      
      fallthrough
      
    case .Completed:
      
      greetingLabel.text = message.summaryText()
      buttonsLayoutView.hidden = true
      
    default:
      break
    }
    
    phoneIcon.tintColor = phoneIconColor
    
  }
  
}
