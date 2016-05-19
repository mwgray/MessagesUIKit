//
//  RTAudioPlot.m
//  ReTxt
//
//  Created by Kevin Wooten on 7/29/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "AudioPlot.h"



@interface AudioPlot () {
  size_t _sampleCount;
  UIBezierPath *_path;
}

@end

@implementation AudioPlot

-(id) initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.contentMode = UIViewContentModeRedraw;
  }
  return self;
}

-(NSUInteger) sampleCount
{
  return _sampleCount;
}

-(void) setSampleCount:(NSUInteger)sampleCount
{
  _sampleCount = sampleCount;
}

-(void) updateSamples:(float *)samples count:(NSUInteger)sampleCount
{
  NSUInteger groupCount = _sampleCount;
  NSUInteger groupSampleCount = (sampleCount + groupCount-1) / groupCount;

  float sampleGroups[groupCount];
  memset(sampleGroups, 0, sizeof(float) * groupCount);
  
  if (samples == NULL) {
    return;
  }

  NSUInteger sample = 0;
  float maxSample = 0;

  for (NSUInteger group=0; group < groupCount; ++group) {

    NSUInteger groupSample;

    for (groupSample=0; groupSample < groupSampleCount && sample < sampleCount; ++groupSample, ++sample) {
      sampleGroups[group] += samples[sample];
    }

    if (sampleGroups[group] > 0 && groupSample > 0) {
      sampleGroups[group] /= (float)groupSample;
    }

    maxSample = MAX(sampleGroups[group], maxSample);
  }

  _path = [UIBezierPath new];

  for (NSUInteger group=0; group < groupCount; ++group) {
    
    if (sampleGroups[group] > 0 && maxSample > 0) {
      sampleGroups[group] /= maxSample;
    }
    if (isnan(sampleGroups[group])) {
      sampleGroups[group] = 0;
    }
    

    CGPoint pt = {group, sampleGroups[group]};

    [_path moveToPoint:pt];
    pt.y = -pt.y;
    [_path addLineToPoint:pt];
  }

  [self setNeedsDisplay];
}

-(void) setProgress:(CGFloat)progress
{
  _progress = progress;

  [self setNeedsDisplay];
}

-(void) drawRect:(CGRect)rect
{
  if (!_path) {
    return;
  }

  CGSize size = self.frame.size;

  CGFloat xScale = _sampleStrokeWidth + ((size.width - (_sampleStrokeWidth*_sampleCount))/(_sampleCount-1));
  CGFloat yScale = size.height / 2.0;

  CGAffineTransform txm = CGAffineTransformMakeTranslation(_sampleStrokeWidth/2.0, yScale);
  txm = CGAffineTransformScale(txm, xScale, yScale);

  UIBezierPath *path = [_path copy];
  path.lineWidth = _sampleStrokeWidth;
  path.lineCapStyle = kCGLineCapRound;

  [path applyTransform:txm];

  UIColor *sampleColor = _sampleColor ? _sampleColor : self.tintColor;
  [sampleColor setStroke];

  [path stroke];

  if (_progress > 0) {

    UIColor *sampleProgressColor = _sampleProgressColor ? _sampleProgressColor : self.tintColor;
    [sampleProgressColor setStroke];

    CGContextClipToRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, _progress * size.width, size.height));

    [path stroke];
  }

}

@end
