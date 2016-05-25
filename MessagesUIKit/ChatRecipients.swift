//
//  ChatRecipients.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 9/28/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit
import TURecipientBar


@objc protocol ChatRecipient : TURecipientProtocol {
  
  var aliases : Set<String> { get }
  
}

class ContactRecipient : NSObject, ChatRecipient {
  
  let contact : Contact
  
  init(contact: Contact) {
    self.contact = contact
  }
  
  func copyWithZone(zone: NSZone) -> AnyObject {
    return ContactRecipient(contact: contact)
  }
  
  var recipientTitle : String {
    return contact.displayFullName
  }
  
  var aliases : Set<String> {
    return Set(contact.aliases.map { $0.rawValue })
  }
  
  override func isEqual(object: AnyObject?) -> Bool {
    
    if let contactRecipient = object as? ContactRecipient {
      return contactRecipient.contact == contact
    }
    
    return false
  }
  
}

class AliasRecipient : NSObject, ChatRecipient {
  
  let title : String
  let alias : String
  
  init(alias: String, title: String) {
    self.alias = alias
    self.title = title
  }
  
  func copyWithZone(zone: NSZone) -> AnyObject {
    return AliasRecipient(alias: alias, title: title)
  }
  
  var recipientTitle : String {
    return AliasDisplayManager.sharedProvider.displayForAlias(alias).fullName
  }
  
  var aliases: Set<String> {
    return Set([alias])
  }
  
  override func isEqual(object: AnyObject?) -> Bool {
    
    if let sar = object as? AliasRecipient {
      return sar.alias == alias
    }
    
    return false
  }
  
}
