//
//  BubbleView.m
//  ReTxt
//
//  Created by Kevin Wooten on 1/27/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "BubbleView.h"


CGFloat BubbleViewTagSize = 9;


@implementation BubbleView

-(id) initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

-(void) awakeFromNib
{
  [self setup];
}

-(void) setup
{
}

+(Class) layerClass
{
  return [CAShapeLayer class];
}

-(void) layoutSubviews
{
  [super layoutSubviews];

  CGRect bounds = self.frame;
  bounds.origin = CGPointZero;

  UIBezierPath *path;
  if (!_quoted) {
    path = [BubbleView untaggedBubblePathForRect:bounds];
  }
  else if (_quoteStyle == BubbleViewQuoteStyleDown) {
    path = [BubbleView downTaggedBubblePathForRect:bounds];
  }
  else {
    path = [BubbleView upTaggedBubblePathForRect:bounds];
  }

  if (_maskSubviews) {

    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    mask.fillColor = [UIColor blackColor].CGColor;

    self.layer.mask = mask;

  }
  else {

    CAShapeLayer *layer = (id)self.layer;
    layer.path = path.CGPath;

    layer.fillColor = _color.CGColor;
  }

}

-(void) setQuoted:(BOOL)quoted
{
  _quoted = quoted;

  [self updateMargins];
}

-(void) setQuoteStyle:(BubbleViewQuoteStyle)quoteStyle
{
  _quoteStyle = quoteStyle;

  [self updateMargins];
}

-(void) updateMargins
{
  if (!_quoted || _maskSubviews) {
    self.layoutMargins = UIEdgeInsetsZero;
  }
  else if (_quoteStyle == BubbleViewQuoteStyleDown) {
    self.layoutMargins = UIEdgeInsetsMake(0, 0, BubbleViewTagSize, 0);
  }
  else {
    self.layoutMargins = UIEdgeInsetsMake(BubbleViewTagSize, 0, 0, 0);
  }
  
  [self setNeedsLayout];
}

+(UIBezierPath *) upTaggedBubblePathForRect:(CGRect)frame
{
  //// Subframes
  CGRect tl = CGRectMake(CGRectGetMinX(frame) - 1.06, CGRectGetMinY(frame) - 1.19, 36.92, 24.6);
  CGRect bl = CGRectMake(CGRectGetMinX(frame) - 0.59, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 14.7, 15.4, 15.45);
  CGRect br = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 14.57, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 14.38, 15.4, 15.45);
  CGRect tr = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 14.9, CGRectGetMinY(frame) + 8.32, 15.4, 15.45);


  //// Path Drawing
  UIBezierPath *pathPath = [UIBezierPath bezierPath];
  [pathPath moveToPoint:CGPointMake(CGRectGetMaxX(bl) - 14.81, CGRectGetMaxY(bl) - 11.27)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMaxX(tl) - 35.86, CGRectGetMaxY(tl) - 3.83)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 30.12, CGRectGetMaxY(tl) - 13.18) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 35.86, CGRectGetMaxY(tl) - 7.89) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 33.52, CGRectGetMaxY(tl) - 11.43)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 30.16, CGRectGetMaxY(tl) - 13.27) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 30.09, CGRectGetMaxY(tl) - 13.27) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 30.16, CGRectGetMaxY(tl) - 13.27)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 6.45, CGRectGetMaxY(tl) - 23.24) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 27.76, CGRectGetMaxY(tl) - 14.3) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 6.45, CGRectGetMaxY(tl) - 23.24)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 4.57, CGRectGetMaxY(tl) - 23.08) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 5.8, CGRectGetMaxY(tl) - 23.51) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 5.11, CGRectGetMaxY(tl) - 23.46)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 3.66, CGRectGetMaxY(tl) - 21.43) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 3.98, CGRectGetMaxY(tl) - 22.71) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 3.66, CGRectGetMaxY(tl) - 22.07)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tl) - 3.66, CGRectGetMaxY(tl) - 14.35) controlPoint1:CGPointMake(CGRectGetMaxX(tl) - 3.66, CGRectGetMaxY(tl) - 21.43) controlPoint2:CGPointMake(CGRectGetMaxX(tl) - 3.66, CGRectGetMaxY(tl) - 16.7)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(tr) + 4.33, CGRectGetMinY(tr) + 0.74)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(tr) + 14.9, CGRectGetMinY(tr) + 11.25) controlPoint1:CGPointMake(CGRectGetMinX(tr) + 10.14, CGRectGetMinY(tr) + 0.74) controlPoint2:CGPointMake(CGRectGetMinX(tr) + 14.9, CGRectGetMinY(tr) + 5.47)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(br) + 14.57, CGRectGetMinY(br) + 3.87)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(br) + 4, CGRectGetMinY(br) + 14.38) controlPoint1:CGPointMake(CGRectGetMinX(br) + 14.57, CGRectGetMinY(br) + 9.65) controlPoint2:CGPointMake(CGRectGetMinX(br) + 9.81, CGRectGetMinY(br) + 14.38)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMaxX(bl) - 4.24, CGRectGetMaxY(bl) - 0.75)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(bl) - 14.81, CGRectGetMaxY(bl) - 11.27) controlPoint1:CGPointMake(CGRectGetMaxX(bl) - 10.05, CGRectGetMaxY(bl) - 0.75) controlPoint2:CGPointMake(CGRectGetMaxX(bl) - 14.81, CGRectGetMaxY(bl) - 5.49)];
  [pathPath closePath];

  return pathPath;
}

+(UIBezierPath *) downTaggedBubblePathForRect:(CGRect)frame
{
  //// Subframes
  CGRect br = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 34.68, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 21.59, 36.92, 24.08);
  CGRect tr = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 13.18, CGRectGetMinY(frame) - 2.23, 15.4, 15.45);
  CGRect tl = CGRectMake(CGRectGetMinX(frame) - 2.31, CGRectGetMinY(frame) - 2.68, 15.2, 15.43);
  CGRect bl = CGRectMake(CGRectGetMinX(frame) - 1.79, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 21.79, 14.73, 14.21);

  //// Path Drawing
  UIBezierPath *pathPath = [UIBezierPath bezierPath];
  [pathPath moveToPoint:CGPointMake(CGRectGetMaxX(tr) - 2.22, CGRectGetMaxY(tr) - 2.71)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMaxX(br) - 2.24, CGRectGetMaxY(br) - 22.06)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 7.99, CGRectGetMaxY(br) - 12.72) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 2.24, CGRectGetMaxY(br) - 18.01) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 4.58, CGRectGetMaxY(br) - 14.47)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 7.94, CGRectGetMaxY(br) - 12.63) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 8.02, CGRectGetMaxY(br) - 12.63) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 7.94, CGRectGetMaxY(br) - 12.63)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 31.66, CGRectGetMaxY(br) - 2.65) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 10.34, CGRectGetMaxY(br) - 11.6) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 31.66, CGRectGetMaxY(br) - 2.65)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 33.53, CGRectGetMaxY(br) - 2.81) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 32.3, CGRectGetMaxY(br) - 2.39) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 33, CGRectGetMaxY(br) - 2.44)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 34.44, CGRectGetMaxY(br) - 4.47) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 34.12, CGRectGetMaxY(br) - 3.19) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 34.44, CGRectGetMaxY(br) - 3.83)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(br) - 34.44, CGRectGetMaxY(br) - 11.55) controlPoint1:CGPointMake(CGRectGetMaxX(br) - 34.44, CGRectGetMaxY(br) - 4.47) controlPoint2:CGPointMake(CGRectGetMaxX(br) - 34.44, CGRectGetMaxY(br) - 9.2)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(bl) + 12.36, CGRectGetMinY(bl) + 12.73)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(bl) + 1.79, CGRectGetMinY(bl) + 2.22) controlPoint1:CGPointMake(CGRectGetMinX(bl) + 6.55, CGRectGetMinY(bl) + 12.73) controlPoint2:CGPointMake(CGRectGetMinX(bl) + 1.79, CGRectGetMinY(bl) + 8)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(tl) + 2.31, CGRectGetMinY(tl) + 13.19)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(tl) + 12.88, CGRectGetMinY(tl) + 2.68) controlPoint1:CGPointMake(CGRectGetMinX(tl) + 2.31, CGRectGetMinY(tl) + 7.41) controlPoint2:CGPointMake(CGRectGetMinX(tl) + 7.07, CGRectGetMinY(tl) + 2.68)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMaxX(tr) - 12.79, CGRectGetMaxY(tr) - 13.22)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMaxX(tr) - 2.22, CGRectGetMaxY(tr) - 2.71) controlPoint1:CGPointMake(CGRectGetMaxX(tr) - 6.98, CGRectGetMaxY(tr) - 13.22) controlPoint2:CGPointMake(CGRectGetMaxX(tr) - 2.22, CGRectGetMaxY(tr) - 8.49)];
  [pathPath closePath];

  return pathPath;
}

+(UIBezierPath *) untaggedBubblePathForRect:(CGRect)frame
{
  //// Subframes
  CGRect bl = CGRectMake(CGRectGetMinX(frame) - 1.48, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 17.16, 17, 18.59);
  CGRect br = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 15.69, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 16.9, 17, 18.59);
  CGRect tr = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) - 15.41, CGRectGetMinY(frame) - 1.96, 17, 18.59);
  CGRect tl = CGRectMake(CGRectGetMinX(frame) - 1.45, CGRectGetMinY(frame) - 1.89, 15.85, 17.29);


  //// Path Drawing
  UIBezierPath *pathPath = [UIBezierPath bezierPath];
  [pathPath moveToPoint:CGPointMake(CGRectGetMinX(bl) + 1.48, CGRectGetMinY(bl) + 7.16)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(bl) + 11.48, CGRectGetMinY(bl) + 17.16) controlPoint1:CGPointMake(CGRectGetMinX(bl) + 1.48, CGRectGetMinY(bl) + 12.68) controlPoint2:CGPointMake(CGRectGetMinX(bl) + 5.96, CGRectGetMinY(bl) + 17.16)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(br) + 5.69, CGRectGetMinY(br) + 16.9)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(br) + 15.69, CGRectGetMinY(br) + 6.9) controlPoint1:CGPointMake(CGRectGetMinX(br) + 11.21, CGRectGetMinY(br) + 16.9) controlPoint2:CGPointMake(CGRectGetMinX(br) + 15.69, CGRectGetMinY(br) + 12.42)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(tr) + 15.41, CGRectGetMinY(tr) + 11.96)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(tr) + 5.41, CGRectGetMinY(tr) + 1.96) controlPoint1:CGPointMake(CGRectGetMinX(tr) + 15.41, CGRectGetMinY(tr) + 6.43) controlPoint2:CGPointMake(CGRectGetMinX(tr) + 10.93, CGRectGetMinY(tr) + 1.96)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(tl) + 11.45, CGRectGetMinY(tl) + 1.89)];
  [pathPath addCurveToPoint:CGPointMake(CGRectGetMinX(tl) + 1.45, CGRectGetMinY(tl) + 11.89) controlPoint1:CGPointMake(CGRectGetMinX(tl) + 5.92, CGRectGetMinY(tl) + 1.89) controlPoint2:CGPointMake(CGRectGetMinX(tl) + 1.45, CGRectGetMinY(tl) + 6.37)];
  [pathPath addLineToPoint:CGPointMake(CGRectGetMinX(bl) + 1.48, CGRectGetMinY(bl) + 7.16)];
  [pathPath closePath];

  return pathPath;
}

@end
