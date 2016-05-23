//
//  AudioPlot.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/22/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


public class AudioPlot : UIView {
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.contentMode = .Redraw
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public var sampleCount: UInt = 32 {
    didSet {
      setNeedsDisplay()
    }
  }
  
  public var sampleColor : UIColor? {
    didSet {
      setNeedsDisplay()
    }
  }
  
  public var sampleProgressColor : UIColor? {
    didSet {
      setNeedsDisplay()
    }
  }
  
  public var sampleStrokeWidth : CGFloat = 1 {
    didSet {
      setNeedsDisplay()
    }
  }
  
  public var progress = CGFloat(0) {
    didSet {
      setNeedsDisplay()
    }
  }
  
  private var path: UIBezierPath?
    
  public func updateSamples(sampleBuffer: UnsafePointer<Float>?, sampleCount: UInt) {
    
    let groupCount = self.sampleCount
    let groupSampleCount = ((sampleCount ?? 0) + groupCount - 1) / groupCount
    
    var sampleGroups = [Float](count: Int(groupCount), repeatedValue: 0)

    guard let sampleBuffer = sampleBuffer else {
      return
    }
    
    let samples = UnsafeBufferPointer(start: sampleBuffer, count: Int(sampleCount))
    var sample: Int = 0
    var maxSample: Float = 0
    
    for group in 0..<groupCount {

      var groupSample: UInt = 0
      let group = Int(group)
      
      while groupSample < groupSampleCount && sample < samples.count {
        
        sampleGroups[group] += samples[sample]

        groupSample += 1
        sample += 1
      }

      if sampleGroups[group] > 0 && groupSample > 0 {
        sampleGroups[group] /= Float(groupSample)
      }
      
      maxSample = max(sampleGroups[group], maxSample)
    }
    
    let path = UIBezierPath()
    
    for group in 0..<groupCount {
      
      let group = Int(group)
      
      if sampleGroups[group] > 0 && maxSample > 0 {
        sampleGroups[group] /= maxSample
      }
      
      if isnan(sampleGroups[group]) {
        sampleGroups[group] = 0
      }
      
      let pt = CGPoint(x: CGFloat(group), y: CGFloat(sampleGroups[group]))
      path.moveToPoint(pt)
      path.addLineToPoint(CGPoint(x: pt.x, y: -pt.y))
    }
    
    self.path = path

    setNeedsDisplay()
  }
  
  public override func drawRect(rect: CGRect) {
    
    guard let path = path?.copy() as? UIBezierPath else {
      return
    }

    let sampleCount = CGFloat(self.sampleCount)
    let size = self.frame.size
    let xScale = sampleStrokeWidth + ((size.width - (sampleStrokeWidth * CGFloat(sampleCount))) / (sampleCount - 1))
    let yScale = size.height / 2.0
    let txm = CGAffineTransformScale(CGAffineTransformMakeTranslation(sampleStrokeWidth / 2.0, yScale),
                                     xScale, yScale)
    
    path.lineWidth = sampleStrokeWidth
    path.lineCapStyle = .Round
    path.applyTransform(txm)
    
    let chosenSampleColor = sampleColor ?? tintColor!
    chosenSampleColor.setStroke()
    
    path.stroke()
    
    if progress > 0 {
      
      let chosenProgressColor = sampleProgressColor ?? tintColor!
      chosenProgressColor.setStroke()
      
      CGContextClipToRect(UIGraphicsGetCurrentContext(),
                          CGRectMake(0, 0, progress * size.width, size.height))
      
      path.stroke()
    }
    
  }

}
