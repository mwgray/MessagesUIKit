//
//  AspectRatioImageView.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/21/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


public class AspectRatioImageView : UIImageView {

  public var tinted : Bool = false {
    didSet {
      if let image = super.image {
        self.image = tinted ?
          image.imageWithRenderingMode(.AlwaysTemplate) :
          image.imageWithRenderingMode(.AlwaysOriginal)
      }
    }
  }

  public override var image : UIImage? {
    get {
      return super.image
    }
    set {
      if let image = newValue {
        super.image = tinted ?
          image.imageWithRenderingMode(.AlwaysTemplate) :
          image.imageWithRenderingMode(.AlwaysTemplate)
      }
      else {
        super.image = newValue
      }
      invalidateIntrinsicContentSize()
      setNeedsUpdateConstraints()
      setNeedsLayout()
    }
  }

  public override func updateConstraints() {

    if let image = image {

      snp_remakeConstraints { make in
      }

      let fit = systemLayoutSizeFittingSize(UILayoutFittingExpandedSize)
      let size = image.size;
      
      if fit.width <= size.width && fit.height == size.height {
        
        snp_makeConstraints { make in
          make.width.equalTo(snp_height).multipliedBy(size.width/size.height)
        }
    
      }
      else if fit.height < size.height && fit.width == size.width {
      
        snp_makeConstraints { make in
          make.height.equalTo(snp_width).multipliedBy(size.height/size.width)
        }
      
      }
      
    }
   
    super.updateConstraints()
  }

}
