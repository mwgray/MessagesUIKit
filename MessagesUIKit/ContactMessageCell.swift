//
//  ContactMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


public class ContactMessageCell : MessageCell {

  
  @IBOutlet var nameLabel : UILabel!
  @IBOutlet var extraLabel : UILabel!
  @IBOutlet var initialsLabel : UILabel!
  
  private var vcardData : NSData!
  
  
  override public func updateWithMessage(message: Message) {

    guard let message = message as? ContactMessage else {
      fatalError("invalid message class")
    }
    
    super.updateWithMessage(message)

    var parts = [String]()
    var initials = ""
    
    if let firstName = message.firstName {
      parts.append(firstName)
      initials += firstName.substringToIndex(firstName.startIndex.advancedBy(1))
    }
    if let lastName = message.lastName {
      parts.append(lastName)
      initials += lastName.substringToIndex(lastName.startIndex.advancedBy(1))
    }

    nameLabel.text = parts.joinWithSeparator(" ")
    initialsLabel.text = initials.uppercaseStringWithLocale(NSLocale.autoupdatingCurrentLocale())
    extraLabel.text = message.extraLabel
    
    vcardData = message.vcardData
  }
  
}
