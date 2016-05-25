//
//  VideoMessageCell.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit
import CocoaLumberjack


public class VideoMessageCell : MessageCell {
  
  
  @IBOutlet var thumbnailImageView : UIImageView!
  @IBOutlet var playbackButton : UIButton!
  @IBOutlet var loadingView : UIActivityIndicatorView!
  @IBOutlet var maxWidthConstraint : NSLayoutConstraint!
  
  override func willBeginDisplaying() {
    super.willBeginDisplaying()
  }
  
  override public func updateWithMessage(message: Message) {

    guard let message = message as? VideoMessage else {
      fatalError("invalid message class")
    }
    
    super.updateWithMessage(message)
    
    let thumbnailKey = message.id.UUIDString + "@thumb"
    
    listenForMediaAvailableWithKey(thumbnailKey)
    
    if let thumbnail = delegate.loadCachedMediaForKey(thumbnailKey, loader: { resolve, fail in
    
      DDLogDebug("Caching message thumbnail \(message.id.UUIDString)")
      
      let imageData = message.thumbnailData ?? NSData()
      
      let image = UIImage(data: imageData) ?? UIImage(id: .VideoError)
      
      resolve(image, imageData.length)
      
    }) as? UIImage {
      
      updateImage(thumbnail)
      
    }
    else {
      
      loadingView.startAnimating()
      
    }
    
  }
  
  func updateImage(image: UIImage) {
    
    thumbnailImageView.image = image
    
    let size = thumbnailImageView.intrinsicContentSize()
    thumbnailImageView.snp_remakeConstraints { make in
      make.width.equalTo(thumbnailImageView.snp_height).multipliedBy(size.width/size.height)
    }

  }
  
  override public func mediaAvailableWithInfo(info: [String : AnyObject]) {
    
    if let thumbnail = info[MessageCellMediaDataAvailableNotificationImage] as? UIImage {
      updateImage(thumbnail)
    }
    
    loadingView.stopAnimating()
  }
  
  override public func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    
    maxWidthConstraint.constant = (superview?.frame.width ?? layoutAttributes.size.width) * 0.70
    
    return super.preferredLayoutAttributesFittingAttributes(layoutAttributes)
  }
  
}
