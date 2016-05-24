//
//  MessageTextView.h
//  MessagesUIKit
//
//  Created by Kevin Wooten on 2/4/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

@import UIKit;


@interface MessageTextView : UITextView

-(NSAttributedString *) attributedTextForImage:(UIImage *)image;
-(NSAttributedString *) attributedTextForString:(NSString *)string;

@end



@interface MessageTextImageAttachment : NSTextAttachment

@end
