//
//  UIImage+Extras.m
//  reTXT
//
//  Created by Kevin Wooten on 5/15/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "UIImage+Extras.h"

#import "UIImage+Alpha.h"

@import ImageIO;
@import MobileCoreServices;
@import AssetsLibrary;
@import ObjectiveC;


CGSize UIImageSizeConstrainedToMaxSize(CGSize size, CGSize maxSize)
{
  CGSize newSize;

  if (size.width > maxSize.width) {
    newSize.width = maxSize.width;
    newSize.height = (newSize.width/size.width)*size.height;

    return UIImageSizeConstrainedToMaxSize(newSize, maxSize);
  }
  else if (size.height > maxSize.height) {
    newSize.height = maxSize.height;
    newSize.width = (newSize.height/size.height)*size.width;

    return UIImageSizeConstrainedToMaxSize(newSize, maxSize);
  }
  else {
    newSize = size;
  }

  return newSize;
}



@implementation UIImage (Extras)

+(UIImage *) imageWithCGImageSource:(CGImageSourceRef)imageSource
{

  CGImageRef imageSourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
  if (!imageSourceImage) {
    return nil;
  }
  @try {

    NSDictionary *imageProps = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));

    static UIImageOrientation imageOrientations[] = {
      UIImageOrientationUp,             // default is UP
      UIImageOrientationUp,             // kCGImagePropertyOrientationUp
      UIImageOrientationUpMirrored,     // kCGImagePropertyOrientationUpMirrored
      UIImageOrientationDown,           // kCGImagePropertyOrientationDown
      UIImageOrientationDownMirrored,   // kCGImagePropertyOrientationDownMirrored
      UIImageOrientationLeftMirrored,   // kCGImagePropertyOrientationLeftMirrored
      UIImageOrientationRight,          // kCGImagePropertyOrientationRight
      UIImageOrientationRightMirrored,  // kCGImagePropertyOrientationRightMirrored
      UIImageOrientationLeft,           // kCGImagePropertyOrientationLeft
    };

    // Get image orientation using table, nil maps to 0, which we map to UP
    UIImageOrientation imageOrientation =
      imageOrientations[[imageProps[(__bridge NSString *)kCGImagePropertyOrientation] intValue]];

    return [[UIImage alloc] initWithCGImage:imageSourceImage scale:1.f orientation:imageOrientation];

  }
  @finally {
    CFRelease(imageSourceImage);
  }

}

-(UIImage *) imageScaledToMaxSize:(CGSize)maxSize
{
  CGSize size = self.size;
  CGSize newSize = UIImageSizeConstrainedToMaxSize(size, maxSize);

  if (CGSizeEqualToSize(size, newSize)) {
    return self;
  }

  // The width & height scales should be equal (no idea why
  // I'm adding this very defensive code)
  CGFloat scale = MIN(size.width/newSize.width, size.height/newSize.height);
  return [UIImage imageWithCGImage:self.CGImage scale:scale orientation:self.imageOrientation];
}

-(UIImage *) imageWithMaxSize:(CGSize)maxSize
{
  CGSize size = self.size;
  CGSize newSize = UIImageSizeConstrainedToMaxSize(size, maxSize);

  if (CGSizeEqualToSize(size, newSize)) {
    return self;
  }

  return [self imageWithSize:newSize];
}

-(UIImage *) imageWithSize:(CGSize)newSize
{

  UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);

  [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];

  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return newImage;
}

-(UIImage *) normalizeOrientation
{
  if (self.imageOrientation == UIImageOrientationUp) {
    return self;
  }

  UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);

  [self drawInRect:(CGRect) {0, 0, self.size}];

  UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return normalizedImage;
}

-(void) drawAtCenterPoint:(CGPoint)point
{
  CGSize size = self.size;

  point.x -= size.width *.5;
  point.y -= size.height * .5;

  [self drawAtPoint:point];
}

-(NSData *) exportOptimizedWithMetadata:(NSDictionary *)metadata type:(NSString **)type
{
  *type = self.hasAlpha ? (__bridge NSString *)kUTTypePNG : (__bridge NSString *)kUTTypeJPEG;

  NSMutableData *imgData = [NSMutableData data];
  CGImageDestinationRef imgDest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)(imgData), (__bridge CFStringRef)*type, 1, NULL);
  @try {

    CGImageDestinationAddImage(imgDest, self.CGImage, (__bridge CFDictionaryRef)metadata);

    if (!CGImageDestinationFinalize(imgDest)) {
      return nil;
    }

    return imgData;
  }
  @finally {
    CFRelease(imgDest);
  }

}

static const char UIImage_Extras_ExternalMetadataKey = 0;

-(NSDictionary *) externalMetadata
{
  return objc_getAssociatedObject(self, &UIImage_Extras_ExternalMetadataKey);
}

-(void) setExternalMetadata:(NSDictionary *)externalMetadata
{
  objc_setAssociatedObject(self, &UIImage_Extras_ExternalMetadataKey, externalMetadata, OBJC_ASSOCIATION_RETAIN);
}

+(NSDictionary *) extractMetadataFromImageData:(NSData *)data
{
  CGImageSourceRef source;
  @try {
    source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    NSDictionary *metadata;
    if (source) {
      metadata = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    }

    return metadata;
  }
  @finally {
    if (source) {
      CFRelease(source);
    }
  }

}

@end
