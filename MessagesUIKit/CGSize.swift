//
//  CGSize.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 10/17/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


extension CGSize {
  
  var halfHeight : CGFloat {
    return height/2
  }
  
  var halfWidth : CGFloat {
    return width/2
  }
  
}

func -(lhs: CGSize, rhs: CGSize) -> CGSize {
  return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

func +(lhs: CGSize, rhs: CGSize) -> CGSize {
  return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

func +=(inout lhs: CGSize, rhs: CGSize) {
  lhs = lhs+rhs
}

func -=(inout lhs: CGSize, rhs: CGSize) {
  lhs = lhs-rhs
}
