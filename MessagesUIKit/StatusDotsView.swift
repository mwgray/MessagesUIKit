//
//  StatusDotsView.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/21/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


public class StatusDotsView : UIView {
  

  private var state = Int(0)
  private var dots = [CAShapeLayer]()
  
  
  public override func layoutSubviews() {
    super.layoutSubviews()

    backgroundColor = UIColor.clearColor()
  
    layer.addSublayer(CAShapeLayer())
    layer.addSublayer(CAShapeLayer())
    layer.addSublayer(CAShapeLayer())
  
    let dotPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, 8, 8))

    for dot in dots {
      dot.fillColor = InternalStyle.dotLightGray.CGColor
      dot.path = dotPath.CGPath
    }

    dots[1].position = CGPointMake(0, 0)
    dots[2].position = CGPointMake(11, 0)
    dots[3].position = CGPointMake(22, 0)

    nextState()
  }
  
  private func nextState() {
    
    CATransaction.begin()

    CATransaction.setCompletionBlock { [weak self] in
      self?.nextState()
    }
    
    let anim1 = CABasicAnimation(keyPath: "fillColor")
    anim1.toValue = state == 0 ? InternalStyle.dotDarkGray.CGColor : InternalStyle.dotLightGray.CGColor
    anim1.duration = 0.5
    dots[0].addAnimation(anim1, forKey: "fillColor")

    let anim2 = CABasicAnimation(keyPath: "fillColor")
    anim2.toValue = state == 0 ? InternalStyle.dotDarkGray.CGColor : InternalStyle.dotLightGray.CGColor
    anim2.duration = 0.5
    dots[1].addAnimation(anim1, forKey: "fillColor")

    let anim3 = CABasicAnimation(keyPath: "fillColor")
    anim3.toValue = state == 0 ? InternalStyle.dotDarkGray.CGColor : InternalStyle.dotLightGray.CGColor
    anim3.duration = 0.5
    dots[2].addAnimation(anim1, forKey: "fillColor")

    CATransaction.commit()
    
    state = (state + 1) % 3
  }
  
}
