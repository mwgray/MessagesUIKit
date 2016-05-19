//
//  AutoLayoutCollectionViewCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/17/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public class AutoLayoutCollectionViewCell : UICollectionViewCell {
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.preservesSuperviewLayoutMargins = true
    contentView.layoutMargins = UIEdgeInsets()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    contentView.translatesAutoresizingMaskIntoConstraints = false    
    contentView.preservesSuperviewLayoutMargins = true
    contentView.layoutMargins = UIEdgeInsets()
  }
  
}
