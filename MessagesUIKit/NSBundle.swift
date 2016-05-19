//
//  NSBundle.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


extension NSBundle {
  
  class func muik_frameworkBundle() -> NSBundle {
    return NSBundle(forClass: MessagesViewController.self)
  }
  
}
