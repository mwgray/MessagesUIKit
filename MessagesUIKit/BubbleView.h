//
//  BubbleView.h
//  ReTxt
//
//  Created by Kevin Wooten on 1/27/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

@import UIKit;


NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM (int, BubbleViewQuoteStyle) {
  BubbleViewQuoteStyleUp,
  BubbleViewQuoteStyleDown,
};


extern CGFloat BubbleViewTagSize;


@interface BubbleView : UIView

@property (assign, nonatomic) BubbleViewQuoteStyle quoteStyle;

@property (retain, nonatomic) IBInspectable UIColor *color;
@property (assign, nonatomic) IBInspectable BOOL quoted;
@property (assign, nonatomic) IBInspectable BOOL maskSubviews;

@end


NS_ASSUME_NONNULL_END
