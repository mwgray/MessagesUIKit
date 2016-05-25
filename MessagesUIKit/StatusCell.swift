//
//  StatusCell.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


class StatusCell : AutoLayoutCollectionViewCell {
  
  
  @IBOutlet var badge : UserBadgeView!
  @IBOutlet var icon : UIImageView!


  override class func layerClass() -> AnyClass {
    return CAShapeLayer.self
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let bounds = self.bounds
    
    //// Subframes
    let tl = CGRect(x: CGRectGetMinX(bounds), y: CGRectGetMinY(bounds), width: 18, height: 18)
    let bl = CGRect(x: CGRectGetMinX(bounds) + 4, y: CGRectGetMinY(bounds) + CGRectGetHeight(bounds) - 12, width: 14, height: 12)
    let tr = CGRect(x: CGRectGetMinX(bounds) + CGRectGetWidth(bounds) - 12, y: CGRectGetMinY(bounds) + 6, width: 12, height: 12)
    let br = CGRect(x: CGRectGetMinX(bounds) + CGRectGetWidth(bounds) - 12, y: CGRectGetMinY(bounds) + CGRectGetHeight(bounds) - 12, width: 12, height: 12)
    
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPoint(x: tl.minX + 4.27, y: tl.minY + 0.73))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 4.27, y: tl.minY + 4.27), controlPoint1:CGPoint(x: tl.minX + 5.24, y: tl.minY + 1.71), controlPoint2:CGPoint(x: tl.minX + 5.24, y: tl.minY + 3.29))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 0.73, y: tl.minY + 4.27), controlPoint1:CGPoint(x: tl.minX + 3.29, y: tl.minY + 5.24), controlPoint2:CGPoint(x: tl.minX + 1.71, y: tl.minY + 5.24))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 0.73, y: tl.minY + 0.73), controlPoint1:CGPoint(x: tl.minX - 0.24, y: tl.minY + 3.29), controlPoint2:CGPoint(x: tl.minX - 0.24, y: tl.minY + 1.71))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 4.27, y: tl.minY + 0.73), controlPoint1:CGPoint(x: tl.minX + 1.71, y: tl.minY - 0.24), controlPoint2:CGPoint(x: tl.minX + 3.29, y: tl.minY - 0.24))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: tl.minX + 12.39, y: tl.minY + 4.61))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 13.43, y: tl.minY + 6.05), controlPoint1:CGPoint(x: tl.minX + 12.82, y: tl.minY + 5.04), controlPoint2:CGPoint(x: tl.minX + 13.17, y: tl.minY + 5.53))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 14.37, y: tl.minY + 6), controlPoint1:CGPoint(x: tl.minX + 13.74, y: tl.minY + 6.02), controlPoint2:CGPoint(x: tl.minX + 14.05, y: tl.minY + 6))
    bezierPath.addLineToPoint(CGPoint(x: tr.minX + 3.63, y: tr.minY))
    bezierPath.addCurveToPoint(CGPoint(x: tr.minX + 12, y: tr.minY + 8.45), controlPoint1:CGPoint(x: tr.minX + 8.23, y: tr.minY), controlPoint2:CGPoint(x: tr.minX + 12, y: tr.minY + 3.8))
    bezierPath.addLineToPoint(CGPoint(x: br.minX + 12, y: br.minY + 3.55))
    bezierPath.addCurveToPoint(CGPoint(x: br.minX + 3.63, y: br.minY + 12), controlPoint1:CGPoint(x: br.minX + 12, y: br.minY + 8.2), controlPoint2:CGPoint(x: br.minX + 8.23, y: br.minY + 12))
    bezierPath.addLineToPoint(CGPoint(x: bl.minX + 10.37, y: bl.minY + 12))
    bezierPath.addCurveToPoint(CGPoint(x: bl.minX + 2, y: bl.minY + 3.55), controlPoint1:CGPoint(x: bl.minX + 5.77, y: bl.minY + 12), controlPoint2:CGPoint(x: bl.minX + 2, y: bl.minY + 8.2))
    bezierPath.addLineToPoint(CGPoint(x: tl.minX + 6, y: tl.minY + 14.45))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 6.06, y: tl.minY + 13.43), controlPoint1:CGPoint(x: tl.minX + 6, y: tl.minY + 14.11), controlPoint2:CGPoint(x: tl.minX + 6.02, y: tl.minY + 13.77))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 4.61, y: tl.minY + 12.39), controlPoint1:CGPoint(x: tl.minX + 5.54, y: tl.minY + 13.17), controlPoint2:CGPoint(x: tl.minX + 5.05, y: tl.minY + 12.83))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 4.61, y: tl.minY + 4.61), controlPoint1:CGPoint(x: tl.minX + 2.46, y: tl.minY + 10.24), controlPoint2:CGPoint(x: tl.minX + 2.46, y: tl.minY + 6.76))
    bezierPath.addCurveToPoint(CGPoint(x: tl.minX + 12.39, y: tl.minY + 4.61), controlPoint1:CGPoint(x: tl.minX + 6.76, y: tl.minY + 2.46), controlPoint2:CGPoint(x: tl.minX + 10.24, y: tl.minY + 2.46))
    bezierPath.closePath()
    
    bezierPath.miterLimit = 4
    
    bezierPath.applyTransform(CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, -bounds.size.height))
    
    let shapeLayer = self.layer as! CAShapeLayer
    shapeLayer.path = bezierPath.CGPath
    shapeLayer.fillColor = InternalStyle.bubbleGray.CGColor
  }
  
}
