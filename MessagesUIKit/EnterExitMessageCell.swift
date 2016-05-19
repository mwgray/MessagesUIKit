//
//  EnterExitMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


public class EnterExitMessageCell : MessageCell {
  
  
  @IBOutlet var name : UILabel!
  @IBOutlet var badge : UserBadgeView!
  
  
  override public func updateWithMessage(message: Message) {
    
    let alias : String, additionalText : String
    
    if let enterMessage = message as? EnterMessage {
      alias = enterMessage.alias
      additionalText = "has joined"
    }
    else if let exitMessage = message as? ExitMessage {
      alias = exitMessage.alias
      additionalText = "has left"
    }
    else {
      fatalError("invalid message")
    }
    
    let aliasDisplay = AliasDisplayManager.sharedProvider.displayForAlias(alias)
    
    name.text = aliasDisplay.fullName
    badge.initials = aliasDisplay.fullName
    badge.avatar = aliasDisplay.avatar
    
    name?.text = (name?.text ?? "") + additionalText
    
  }
  
}
