//
//  UIImage+Alpha.h
//  MessagesUIKit
//
//  Created by Kevin Wooten on 2/22/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Alpha)

-(BOOL) hasAlpha;
-(UIImage *) imageWithAlpha;
-(UIImage *) transparentBorderImage:(NSUInteger)borderSize;

@end
