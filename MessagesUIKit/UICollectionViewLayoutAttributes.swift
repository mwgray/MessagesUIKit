//
//  UICollectionViewLayoutAttributes.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/20/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public extension UICollectionViewLayoutAttributes {
  
  public var position : CGPoint {
    get {
      return frame.origin
    }
    set {
      frame = CGRect(origin: newValue, size: size)
    }
  }
  
}
