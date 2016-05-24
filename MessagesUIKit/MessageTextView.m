//
//  MessageTextView.m
//  MessagesUIKit
//
//  Created by Kevin Wooten on 2/4/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

#import "MessageTextView.h"

#import "UIImage+Extras.h"
#import "UIImage+ImageEffects.h"

@import MobileCoreServices;
@import ImageIO;


@interface MessageTextView () <NSTextStorageDelegate> {

  UIFont *_originalFont;

}

@end



@implementation MessageTextView

-(instancetype) initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
  self = [super initWithFrame:frame textContainer:textContainer];
  if (self) {
    [self commonInit];
  }
  return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self commonInit];
  }
  return self;
}

-(void) commonInit
{
  _originalFont = self.font;
  self.textStorage.delegate = self;
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(paste:)) {
    NSArray *types = @[];
    types = [types arrayByAddingObjectsFromArray:UIPasteboardTypeListString];
    types = [types arrayByAddingObjectsFromArray:UIPasteboardTypeListImage];
    types = [types arrayByAddingObjectsFromArray:UIPasteboardTypeListURL];
    return [UIPasteboard.generalPasteboard containsPasteboardTypes:types];
  }

  return [super canPerformAction:action withSender:sender];
}

-(NSAttributedString *) attributedTextForImage:(UIImage *)image
{
  MessageTextImageAttachment *imageAttachment = [MessageTextImageAttachment new];
  imageAttachment.image = image;

  unichar imageChar = NSAttachmentCharacter;
  NSAttributedString *imageString = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&imageChar length:1]
                                                                    attributes:@{NSFontAttributeName: _originalFont,
                                                                                 @"NSOriginalFont": _originalFont,
                                                                                 NSAttachmentAttributeName: imageAttachment}];

  return imageString;
}

-(NSAttributedString *) attributedTextForString:(NSString *)string
{
  return [[NSAttributedString alloc] initWithString:string
                                         attributes:@{NSFontAttributeName:_originalFont}];
}

-(void) paste:(id)sender
{
  NSMutableAttributedString *pasted = [NSMutableAttributedString new];

  UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;

  for (NSUInteger pasteboardItem=0; pasteboardItem < pasteboard.numberOfItems; ++pasteboardItem) {

    NSIndexSet *pasteboardItemIndexSet = [NSIndexSet indexSetWithIndex:pasteboardItem];

    if ([pasteboard containsPasteboardTypes:@[(__bridge NSString *)kUTTypeImage] inItemSet:pasteboardItemIndexSet]) {

      NSArray *imageDatas = [pasteboard dataForPasteboardType:(__bridge NSString *)kUTTypeImage
                                                    inItemSet:pasteboardItemIndexSet];

      NSData *imageData = imageDatas[0];

      UIImage *image = [UIImage imageWithData:imageDatas[0]];
      image.externalMetadata = [UIImage extractMetadataFromImageData:imageData];

      [pasted appendAttributedString:[self attributedTextForImage:image]];

    }
    else if ([pasteboard containsPasteboardTypes:@[(__bridge NSString *)kUTTypeText] inItemSet:pasteboardItemIndexSet]) {

      NSArray *texts = [pasteboard valuesForPasteboardType:(__bridge NSString *)kUTTypeText
                                                 inItemSet:pasteboardItemIndexSet];

      NSString *text = texts[0];

      [pasted appendAttributedString:[self attributedTextForString:text]];

    }
    else if ([pasteboard containsPasteboardTypes:@[(__bridge NSString *)kUTTypeURL] inItemSet:pasteboardItemIndexSet]) {

      NSArray *URLs = [pasteboard valuesForPasteboardType:(__bridge NSString *)kUTTypeURL
                                                 inItemSet:pasteboardItemIndexSet];
      
      NSURL *URL = URLs[0];
      
      [pasted appendAttributedString:[self attributedTextForString:URL.absoluteString]];
      
    }

  }


  NSRange replaceRange;
  if (self.selectedTextRange) {
    replaceRange = self.selectedRange;
  }
  else {
    replaceRange = NSMakeRange(0, 0);
  }

  if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
    if (![self.delegate textView:self shouldChangeTextInRange:replaceRange replacementText:pasted.string]) {
      return;
    }
  }

  [self.textStorage replaceCharactersInRange:replaceRange withAttributedString:pasted];

  if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
    [self.delegate textViewDidChange:self];
  }

  self.selectedRange = NSMakeRange(replaceRange.location + pasted.length, 0);

  if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
    [self.delegate textViewDidChangeSelection:self];
  }
}

@end





@implementation MessageTextImageAttachment

-(UIImage *) imageForBounds:(CGRect)imageBounds textContainer:(NSTextContainer *)textContainer characterIndex:(NSUInteger)charIndex
{
  return [[self.image imageScaledToMaxSize:textContainer.size] roundCornersWithRadius:10];
}

-(CGRect) attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
  if (!self.image) {
    return CGRectZero;
  }

  CGSize size = textContainer.size;
  size.width -= 15;
  size.height = CGFLOAT_MAX;

  size = UIImageSizeConstrainedToMaxSize(self.image.size, size);
  return CGRectMake(0, 0, size.width, size.height);
}

@end
