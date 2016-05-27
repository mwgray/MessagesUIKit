//
//  PickAddressBookRecipientOperation.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/26/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation
import PSOperations
import MessagesKit
import AddressBook
import AddressBookUI


public class PickAddressBookContactOperation : PickContactOperation, ABPeoplePickerNavigationControllerDelegate {
  
  private let viewController: UIViewController
  
  public init(viewController: UIViewController) {
    
    self.viewController = viewController
    
    super.init()
    
    addCondition(ModalCondition())
  }
  
  public override func execute() {
    
    let picker = ABPeoplePickerNavigationController()
    picker.displayedProperties = [NSNumber(int: kABPersonPhoneProperty), NSNumber(int: kABPersonEmailProperty)]
    picker.predicateForSelectionOfPerson = NSPredicate(value: false)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    picker.peoplePickerDelegate = self
    
    GCD.mainQueue.async {
      self.viewController.presentViewController(picker, animated: true, completion: nil)
    }
  }
  
  public func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
    
    contact = PersonAliasDisplay(person: AddressBookPerson(record: person))
    
    viewController.dismissViewControllerAnimated(true) {
      self.finish()
    }
    
  }
  
  public func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController) {
    
    viewController.dismissViewControllerAnimated(true) {
      self.finish()
    }
  }
  
}
