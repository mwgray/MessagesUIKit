//
//  Contact.swift
//  reTXT
//
//  Created by Kevin Wooten on 5/15/16.
//  Copyright © 2016 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


@objc public protocol ContactAlias {
  
  var type : String { get }
  
  var displayValue : String { get }
  
  var rawValue : String { get }
  
}


@objc public protocol Contact : NSObjectProtocol {
  
  var displayFullName : String { get }
  
  var displayFamiliarName : String { get }
  
  var displayInitials : String { get }
  
  var displayAvatar : UIImage? { get }
  
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
  
  public class func initialize(sharedProvider sharedProvider: ContactsProvider) {
    _sharedProvider = sharedProvider
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



extension AddressBookMultivalueEntry : ContactAlias {
  
  public var type : String { return self.label ?? "" }
  
  public var displayValue : String { return self.value as! String }

  public var rawValue : String { return self.value as! String }
  
}

extension AddressBookPerson : Contact {
  
  @objc public var displayFullName : String { return self.compositeName ?? "" }
  
  @objc public var displayFamiliarName : String { return self.nickname ?? self.firstName ?? self.compositeName ?? "" }
  
  @objc public var displayInitials : String { return displayFullName.componentsSeparatedByString(" ").map { $0.substringToIndex($0.startIndex.advancedBy(1)) }.joinWithSeparator("") }
  
  @objc public var displayAvatar : UIImage? { return self.image }
  
  @objc public var aliases : [ContactAlias] { return (self.phoneNumbers ?? []) + (self.emails ?? []) }
  
}


@objc public class AddressBookIndexContactsProvider : NSObject, ContactsProvider {
  
  private let index : AddressBookIndex
  
  public init(index: AddressBookIndex) {
    self.index = index
  }
  
  public var accessGranted: Bool {
    return true
  }
  
  public func searchWithQuery(query: String) -> [Contact] {
    return index.searchPeopleWithQuery(query)
  }
  
  public func searchWithAliases(aliases: [String]) -> [Contact] {
    return index.lookupPeopleWithAliases(aliases)
  }
  
}
