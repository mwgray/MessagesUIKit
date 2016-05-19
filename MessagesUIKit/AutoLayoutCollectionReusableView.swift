//
//  AutoLayoutCollectionReusableView.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/17/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public class AutoLayoutCollectionReusableView : UICollectionReusableView {
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    translatesAutoresizingMaskIntoConstraints = false
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
}
