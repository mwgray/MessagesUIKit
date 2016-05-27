//
//  Contact.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/15/16.
//  Copyright © 2016 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


@objc public enum ContactAliasKind : Int {
  case Phone
  case Email
  case InstantMessage
  case Other
}

@objc public protocol ContactAlias {
  
  var kind : ContactAliasKind { get }
  
  var label : String? { get }
  
  var value : String { get }
  
}


@objc public protocol Contact : NSObjectProtocol, AliasDisplay {
  
  var aliases : Array<ContactAlias> { get }
  
}


public func ==(lhs: Contact, rhs: Contact) -> Bool {
  return lhs.isEqual(rhs)
}


@objc public protocol ContactsProvider {
  
  var accessGranted : Bool { get }
  
  func searchWithAliases(aliases: [String]) -> [Contact]
  
  func searchWithQuery(query: String) -> [Contact]
  
}


@objc public class ContactsManager : NSObject {
  
  private static var _sharedProvider : ContactsProvider = DefaultContactsProvider()
  
  public class func initialize(provider provider: ContactsProvider) {
    _sharedProvider = provider
  }
  
  public class var sharedProvider : ContactsProvider {
    return _sharedProvider
  }
  
}


@objc public class DefaultContactsProvider : NSObject, ContactsProvider {
  
  public var accessGranted: Bool {
    return false
  }
  
  public func searchWithAliases(aliases: [String]) -> [Contact] {
    return []
  }
  
  public func searchWithQuery(query: String) -> [Contact] {
    return []
  }
  
}
