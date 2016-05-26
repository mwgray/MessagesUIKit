//
//  AddressBookContacts.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/26/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation
import MessagesKit


class AddressBookPersonContactAlias : NSObject, ContactAlias {
  
  let entry : AddressBookMultivalueEntry
  
  init(entry: AddressBookMultivalueEntry) {
    self.entry = entry
  }
  
  var type: String? { return entry.label ?? "" }
  
  var displayValue: String { return entry.value as! String }
  
  var value: String { return entry.value as! String }
  
}

extension PersonAliasDisplay : Contact {
  
  public var aliases : [ContactAlias] {
    return
      (person.phoneNumbers?.map({ AddressBookPersonContactAlias(entry: $0) }) ?? []) +
        (person.emails?.map({ AddressBookPersonContactAlias(entry: $0) }) ?? [])
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
