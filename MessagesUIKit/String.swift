//
//  String.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


extension String {
  
  func extractInitials() -> String? {
    return self.componentsSeparatedByString(" ")
      .map { $0.substringToIndex($0.startIndex.advancedBy(1)) }
      .joinWithSeparator("")
  }
  
}