//
//  CGSize.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/17/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


extension CGSize {
  
  public var halfHeight : CGFloat {
    return height/2
  }
  
  public var halfWidth : CGFloat {
    return width/2
  }
  
}

public func -(lhs: CGSize, rhs: CGSize) -> CGSize {
  return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

public func +(lhs: CGSize, rhs: CGSize) -> CGSize {
  return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

public func +=(inout lhs: CGSize, rhs: CGSize) {
  lhs = lhs+rhs
}

public func -=(inout lhs: CGSize, rhs: CGSize) {
  lhs = lhs-rhs
}
