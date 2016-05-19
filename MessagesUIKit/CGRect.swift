//
//  CGRect.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/19/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


extension CGRect {
  
  public func inset(insets: UIEdgeInsets) -> CGRect {
    return UIEdgeInsetsInsetRect(self, insets)
  }
  
  public func outset(insets: UIEdgeInsets) -> CGRect {
    return UIEdgeInsetsInsetRect(self, UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right))
  }
  
  public func enlargeBy(size: CGSize) -> CGRect {
    return CGRect(origin: origin, size: self.size + size)
  }
  
}
