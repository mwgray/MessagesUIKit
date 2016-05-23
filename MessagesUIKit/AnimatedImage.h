//
//  AnimatedImage.h
//  MessagesKit
//
//  Created by Kevin Wooten on 5/21/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//
//  Based on:
//
//  FLAnimatedImage.h
//  Flipboard
//
//  Created by Raphael Schaad on 7/8/13.
//  Copyright (c) 2013-2015 Flipboard. All rights reserved.
//

@import UIKit;
@import ImageIO;


NS_ASSUME_NONNULL_BEGIN


extern const NSTimeInterval kAnimatedImageDelayTimeIntervalMinimum;

//
//  An `AnimatedImage`'s job is to deliver frames in a highly performant way and works in conjunction with `AnimatedImageView`.
//  It subclasses `NSObject` and not `UIImage` because it's only an "image" in the sense that a sea lion is a lion.
//  It tries to intelligently choose the frame cache size depending on the image and memory situation with the goal to lower CPU usage for smaller ones, lower memory usage for larger ones and always deliver frames for high performant play-back.
//  Note: `posterImage`, `size`, `loopCount`, `delayTimes` and `frameCount` don't change after successful initialization.
//
@interface AnimatedImage : NSObject

@property (nonatomic, strong, readonly) UIImage *posterImage; // Guaranteed to be loaded; usually equivalent to `-imageLazilyCachedAtIndex:0`
@property (nonatomic, assign, readonly) CGSize size; // The `.posterImage`'s `.size`

@property (nonatomic, assign, readonly) NSUInteger loopCount; // 0 means repeating the animation indefinitely
@property (nonatomic, strong, readonly) NSDictionary *delayTimesForIndexes; // Of type `NSTimeInterval` boxed in `NSNumber`s
@property (nonatomic, assign, readonly) NSUInteger frameCount; // Number of valid frames; equal to `[.delayTimes count]`

@property (nonatomic, assign, readonly) NSUInteger frameCacheSizeCurrent; // Current size of intelligently chosen buffer window; can range in the interval [1..frameCount]
@property (nonatomic, assign) NSUInteger frameCacheSizeMax; // Allow to cap the cache size; 0 means no specific limit (default)

// Intended to be called from main thread synchronously; will return immediately.
// If the result isn't cached, will return `nil`; the caller should then pause playback, not increment frame counter and keep polling.
// After an initial loading time, depending on `frameCacheSize`, frames should be available immediately from the cache.
-(nullable UIImage *)imageLazilyCachedAtIndex:(NSUInteger)index;

// Pass either a `UIImage` or an `AnimatedImage` and get back its size
+(CGSize)sizeForImage:(id)image;

-(instancetype) init NS_UNAVAILABLE;

// On success, the initializers return an `AnimatedImage` with all fields initialized, on failure they return `nil` and an error will be logged.
-(nullable instancetype)initWithData:(NSData *)data;
-(nullable instancetype)initWithURL:(NSURL *)url;
-(nullable instancetype)initWithSource:(CGImageSourceRef)source;

// Pass 0 for optimalFrameCacheSize to get the default, predrawing is enabled by default.
-(nullable instancetype)initWithSource:(CGImageSourceRef)source optimalFrameCacheSize:(NSUInteger)optimalFrameCacheSize predrawingEnabled:(BOOL)isPredrawingEnabled NS_DESIGNATED_INITIALIZER;

+(nullable instancetype)animatedImageWithData:(NSData *)data;
+(nullable instancetype)animatedImageWithURL:(NSURL *)url;

@end


@interface AnimatedImageWeakProxy : NSProxy

+(instancetype)weakProxyForObject:(id)targetObject;

@end


NS_ASSUME_NONNULL_END
