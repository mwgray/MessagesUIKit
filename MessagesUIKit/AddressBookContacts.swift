//
//  AddressBookContacts.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/26/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation
import MessagesKit
import AddressBook


class AddressBookPersonContactAlias : NSObject, ContactAlias {
  
  let entry : AddressBookMultivalueEntry
  
  init(kind: ContactAliasKind, entry: AddressBookMultivalueEntry) {
    self.kind = kind
    self.entry = entry
  }
  
  let kind : ContactAliasKind
  
  var label: String? { return entry.label != nil ? ABAddressBookCopyLocalizedLabel(entry.label).takeRetainedValue() as String : nil }
  
  var displayValue: String { return entry.value as! String }
  
  var value: String { return entry.value as! String }
  
}

extension PersonAliasDisplay : Contact {
  
  public var aliases : [ContactAlias] {
    return
      (person.phoneNumbers?.map({ AddressBookPersonContactAlias(kind: .Phone, entry: $0) }) ?? []) +
      (person.emails?.map({ AddressBookPersonContactAlias(kind: .Email, entry: $0) }) ?? [])
  }
  
}


@objc public class AddressBookContactsProvider : AddressBookAliasDisplayProvider, ContactsProvider {
  
  public var accessGranted: Bool {
    return true
  }
  
  public func searchWithQuery(query: String) -> [Contact] {
    return index.searchPeopleWithQuery(query).map { PersonAliasDisplay(person: $0) }
  }
  
  public func searchWithAliases(aliases: [String]) -> [Contact] {
    return index.lookupPeopleWithAliases(aliases).map { PersonAliasDisplay(person: $0) }
  }
  
}
