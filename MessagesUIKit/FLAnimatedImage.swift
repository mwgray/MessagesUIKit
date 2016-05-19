//
//  FLAnimatedImage.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/18/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import FLAnimatedImage


extension FLAnimatedImageView {
  
  public var anyImage : AnyObject? {
    get {
      return animatedImage ?? image ?? nil
    }
    set {
      if let animImage = newValue as? FLAnimatedImage {
        animatedImage = animImage
      }
      else if let stillImage = newValue as? UIImage {
        image = stillImage
      }
    }
  }
  
}
