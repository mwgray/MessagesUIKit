//
//  RTAudioPlot.h
//  ReTxt
//
//  Created by Kevin Wooten on 7/29/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

@import UIKit;


NS_ASSUME_NONNULL_BEGIN


@interface AudioPlot : UIView

@property (assign, nonatomic) NSUInteger sampleCount;

@property (strong, nonatomic) UIColor *sampleColor;
@property (strong, nonatomic) UIColor *sampleProgressColor;

@property (assign, nonatomic) CGFloat sampleStrokeWidth;
@property (assign, nonatomic) CGFloat progress;

-(void) updateSamples:(float *)samples count:(NSUInteger)sampleCount;

@end


NS_ASSUME_NONNULL_END
