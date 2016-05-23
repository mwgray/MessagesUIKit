//
//  TextMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit


public class TextMessageCell : MessageCell {
  
  
  @IBOutlet var textView : UITextView!
  @IBOutlet var maxWidthConstraint : NSLayoutConstraint!
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
  }
  
  override public func updateWithMessage(message: Message) {

    guard let message = message as? TextMessage else {
      fatalError("invalid message class")
    }
    
    super.updateWithMessage(message)
    
    if (message.type == .Html) {
      
      textView.attributedText = HTMLTextParser(defaultFont: textView.font).parseWithData(message.data as! NSData)
      
    }
    else {
     
      textView.text = message.text
      
    }
    
  }
  
  override public func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    
    maxWidthConstraint.constant = (superview?.frame.width ?? layoutAttributes.size.width) * 0.70
    
    return super.preferredLayoutAttributesFittingAttributes(layoutAttributes)
  }
  
}
