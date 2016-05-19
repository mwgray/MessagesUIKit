//
//  UIEdgeInsets.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public extension UIEdgeInsets {
  
  public var totalHorizontal : CGFloat {
    return left + right
  }
  
  public var totalVertical : CGFloat {
    return top + bottom
  }
  
}
