//
//  CGPoint.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/23/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x+rhs.x, y: lhs.y+rhs.y)
}

public func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x-rhs.x, y: lhs.y-rhs.y)
}

public func +=(inout lhs: CGPoint, rhs: CGPoint) {
  lhs = lhs + rhs
}

public func -=(inout lhs: CGPoint, rhs: CGPoint) {
  lhs = lhs - rhs
}
