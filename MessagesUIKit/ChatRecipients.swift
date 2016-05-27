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


@objc public protocol ChatRecipient : TURecipientProtocol {
  
  var alias : String { get }
  
}


public class ContactChatRecipient : NSObject, ChatRecipient {
  
  let contact : Contact
  
  public let alias: String
  
  public init(contact: Contact, alias: String) {
    self.contact = contact
    self.alias = alias
  }
  
  public func copyWithZone(zone: NSZone) -> AnyObject {
    return ContactChatRecipient(contact: contact, alias: alias)
  }
  
  public var recipientTitle : String {
    return contact.fullName
  }
  
  public override func isEqual(object: AnyObject?) -> Bool {
    
    if let contactRecipient = object as? ContactChatRecipient {
      return contactRecipient.contact == contact
    }
    
    return false
  }
  
}


public class AliasChatRecipient : NSObject, ChatRecipient {
  
  public let recipientTitle : String
  public let alias : String
  
  public init(alias: String, title: String) {
    self.alias = alias
    self.recipientTitle = title
  }
  
  public func copyWithZone(zone: NSZone) -> AnyObject {
    return AliasChatRecipient(alias: alias, title: recipientTitle)
  }
  
  public override func isEqual(object: AnyObject?) -> Bool {
    
    if let sar = object as? AliasChatRecipient {
      return sar.alias == alias
    }
    
    return false
  }
  
}
