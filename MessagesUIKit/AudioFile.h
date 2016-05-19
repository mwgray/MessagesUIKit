//
//  AudioFile.h
//  ReTxt
//
//  Created by Kevin Wooten on 8/6/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

@import Foundation;


@interface AudioFile : NSObject

@property (readonly, nonatomic) NSURL *url;
@property (readonly, nonatomic) NSInteger size;
@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) SInt64 totalFrames;

@property (readonly, nonatomic) BOOL hasSamples;
@property (readonly, nonatomic) float *samples;
@property (readonly, nonatomic) NSUInteger sampleCount;

-(instancetype) initWithURL:(NSURL *)url;

-(BOOL) openWithError:(NSError **)error;

-(void) generateSampleData:(NSUInteger)requestedSamples
                completion:(void (^)())completion
                     error:(void (^)(NSError *error))error;

@end
