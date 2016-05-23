//
//  PieProgressView.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/21/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


public class PieProgressView: UIView {
  
  public var radius: CGFloat = 1
  
  private var _percent : CGFloat = 0
  
  public var percent: CGFloat {
    get {
      return _percent
    }
    set {
      _percent = max(0, min(1, newValue))
      setNeedsDisplay()
    }
  }
  
  // 0..1
  public var strokeWidth: CGFloat = 1
  public var color: UIColor = UIColor.whiteColor()
  
  public override required init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }
  
  private func setup() {
    self.opaque = false
    self.clearsContextBeforeDrawing = true
    self.contentMode = .Redraw
  }
  
  public override func intrinsicContentSize() -> CGSize {
    return CGSizeMake(radius * 2 + strokeWidth, radius * 2 + strokeWidth)
  }
  
  public override func drawRect(rect: CGRect) {
    
    if let context = UIGraphicsGetCurrentContext() {
      
      color.setStroke()
      color.setFill()
      
      let halfw: CGFloat = self.bounds.size.width * 0.5
      let halfh: CGFloat = self.bounds.size.height * 0.5
      let radius: CGFloat = (self.bounds.size.width - self.strokeWidth) * 0.5
      
      CGContextSetLineWidth(context, self.strokeWidth)
      CGContextBeginPath(context)
      CGContextAddArc(context, halfw, halfh, radius, 0, CGFloat(M_PI) * 2, 0)
      CGContextStrokePath(context)
      CGContextBeginPath(context)
      CGContextMoveToPoint(context, halfw, halfh)
      CGContextAddArc(context, halfw, halfh, radius, 0 - CGFloat(M_PI_2), (CGFloat(M_PI) * 2 * percent) - CGFloat(M_PI_2), 0)
      CGContextClosePath(context)
      CGContextFillPath(context)
    }
  }
  
}
