//
//  UIImage+Extras.h
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/15/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

@import UIKit;
@import ImageIO;


NS_ASSUME_NONNULL_BEGIN


@interface UIImage (Extras)

-(UIImage *) imageScaledToMaxSize:(CGSize)maxSize;

-(UIImage *) imageWithMaxSize:(CGSize)maxSize;
-(UIImage *) imageWithSize:(CGSize)newSize;
-(UIImage *) normalizeOrientation;

-(void) drawAtCenterPoint:(CGPoint)point;

-(NSData *) exportOptimizedWithMetadata:(nullable NSDictionary *)metadata type:(NSString *__autoreleasing __nonnull *__nonnull)type;

@property (strong, nonatomic, nullable) NSDictionary *externalMetadata;

+(nullable NSDictionary *) extractMetadataFromImageData:(NSData *)data;

+(nullable UIImage *) imageWithSource:(CGImageSourceRef)imageSource;

@end


NS_ASSUME_NONNULL_END


CGSize UIImageSizeConstrainedToMaxSize(CGSize size, CGSize maxSize);
