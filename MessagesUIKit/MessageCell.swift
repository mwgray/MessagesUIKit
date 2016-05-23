//
//  ContentMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit
import SnapKit



public protocol MessageCellDelegate {

  func loadCachedMediaForKey(key: AnyObject, loader: (resolved: (AnyObject, Int) -> Void, failed: (NSError?) -> Void ) -> Void) -> AnyObject?
  
}



public let MessageCellMediaDataAvailableNotification = "MessageCellMediaDataAvailable"
public let MessageCellMediaDataAvailableNotificationMediaIdKey = "mediaId"
public let MessageCellMediaDataAvailableNotificationImage = "image"
public let MessageCellMediaDataAvailableNotificationAudio = "audio"

public let MessageCellMediaPlayProgressNotification = "MessageCellMediaPlayProgressNotification"
public let MessageCellMediaPlayProgressNotificationMediaIdKey = "mediaId"
public let MessageCellMediaPlayProgressNotificationPercentKey = "percent"
public let MessageCellMediaPlayProgressNotificationStatusKey = "status"


public enum MessageCellMediaPlayStatus : Int {
  case Stopped
  case Paused
  case Playing
}


public class MessageCell : AutoLayoutCollectionViewCell {
  
  
  @IBOutlet var bubbleView : BubbleView!
  
  var delegate : MessageCellDelegate!
  
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    
    bubbleView.quoted = false
  }
  
  func willBeginDisplaying() {
    
  }
  
  func didEndDisplaying() {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  public override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

    let result = super.preferredLayoutAttributesFittingAttributes(layoutAttributes) as! MessagesViewLayoutAttributes

    // Setup size & alignment for quote ornament
    if result.ornaments?.contains(.Quote) ?? false {      
      result.alignmentRectInsets = bubbleView.layoutMargins
    }
    
    return result
  }

  public override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
    super.applyLayoutAttributes(layoutAttributes)
    
    if let layoutAttributes = layoutAttributes as? MessagesViewLayoutAttributes {

        // Enable quote
        if let ornaments = layoutAttributes.ornaments {
          if ornaments.contains(.Quote) {
            bubbleView.quoted = true
          }
        }
        
    }
    
  }
  
  public func updateWithMessage(message: Message) {
        
  }
  
  public func listenForMediaAvailableWithKey(key: AnyObject) {
    
    NSNotificationCenter.defaultCenter()
      .addObserver(self, selector: #selector(MessageCell.mediaAvailable(_:)), name: MessageCellMediaDataAvailableNotification, object: key)
    
  }
  
  public func mediaAvailable(notification: NSNotification) {
    mediaAvailableWithInfo(notification.userInfo as! [String: AnyObject])
  }
  
  public func mediaAvailableWithInfo(info: [String: AnyObject]) {
    
  }
  
  public func listenForMediaPlayProgressWithKey(key: AnyObject) {
    
    NSNotificationCenter.defaultCenter()
      .addObserver(self, selector: #selector(MessageCell.mediaPlayProgress(_:)), name: MessageCellMediaPlayProgressNotification, object: key)
    
  }
  
  public func mediaPlayProgress(notification: NSNotification) {
    mediaPlayProgressWithInfo(notification.userInfo as! [String: NSNotification])
  }
  
  public func mediaPlayProgressWithInfo(info: [String: AnyObject]) {
    
  }
  
}
