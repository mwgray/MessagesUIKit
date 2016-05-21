//
//  AnimatedImage.h
//  MessagesKit
//
//  Created by Kevin Wooten on 5/21/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//
//  Based on:
//
//  FLAnimatedImageView.h
//  Flipboard
//
//  Created by Raphael Schaad on 7/8/13.
//  Copyright (c) 2013-2015 Flipboard. All rights reserved.
//

@import UIKit;


NS_ASSUME_NONNULL_BEGIN


@class AnimatedImage;
@protocol AnimatedImageViewDebugDelegate;


//
//  An `AnimatedImageView` can take an `AnimatedImage` and plays it automatically when in view hierarchy and stops when removed.
//  The animation can also be controlled with the `UIImageView` methods `-start/stop/isAnimating`.
//  It is a fully compatible `UIImageView` subclass and can be used as a drop-in component to work with existing code paths expecting to display a `UIImage`.
//  Under the hood it uses a `CADisplayLink` for playback, which can be inspected with `currentFrame` & `currentFrameIndex`.
//
@interface AnimatedImageView : UIImageView

// Setting `[UIImageView.image]` to a non-`nil` value clears out existing `animatedImage`.
// And vice versa, setting `animatedImage` will initially populate the `[UIImageView.image]` to its `posterImage` and then start animating and hold `currentFrame`.
@property (strong, nullable, nonatomic) AnimatedImage *animatedImage;
@property (copy, nonatomic) void(^loopCompletionBlock)(NSUInteger loopCountRemaining);

@property (strong, nullable, nonatomic) id anyImage;

@property (readonly, nullable, nonatomic) UIImage *currentFrame;
@property (readonly, nonatomic) NSUInteger currentFrameIndex;

// The animation runloop mode. Enables playback during scrolling by allowing timer events (i.e. animation) with NSRunLoopCommonModes.
// To keep scrolling smooth on single-core devices such as iPhone 3GS/4 and iPod Touch 4th gen, the default run loop mode is NSDefaultRunLoopMode. Otherwise, the default is NSDefaultRunLoopMode.
@property (nonatomic, copy) NSString *runLoopMode;

@end


NS_ASSUME_NONNULL_END
