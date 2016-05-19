//
//  LocationMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit
import CoreLocation


public class LocationMessageCell : MessageCell {
  
  
  @IBOutlet private var thumbnailImageView : UIImageView!
  @IBOutlet private var loadingView : UIActivityIndicatorView!
  @IBOutlet var maxWidthConstraint : NSLayoutConstraint!
  
  private var coordinates : CLLocationCoordinate2D!
  private var title : String!
  private var locationURL : NSURL!
  
  
  override func willBeginDisplaying() {
    super.willBeginDisplaying()
  }
  
  override public func updateWithMessage(message: Message) {

    guard let message = message as? LocationMessage else {
      fatalError("invalid message class")
    }
    
    super.updateWithMessage(message)
    
    
    title = message.title
    coordinates = CLLocationCoordinate2D(latitude: message.latitude, longitude: message.longitude)
    
    let locationURLBuilder = NSURLComponents()
    locationURLBuilder.scheme = "message"
    locationURLBuilder.host = "location"
    locationURLBuilder.path = message.id.UUIDString()
    
    let locationURL = locationURLBuilder.URL!
    
    self.locationURL = locationURL

    let thumbnailKey = message.id.UUIDString() + "-thumb"
    
    listenForMediaAvailableWithKey(thumbnailKey)
    
    if let thumbnail = delegate.loadCachedMediaForKey(thumbnailKey, loader: { resolve, fail in
    
      if let data = message.thumbnailData {
        
        guard let thumbnail = UIImage(data: data) else {
          
          fail(nil)
          
          return
        }
        
        resolve(thumbnail, data.length)
        
      }
      else {
    
        LocationMessage.generateThumbnailData(message) { data, error in
          
          if error == nil {
            
            message.thumbnailData = data
            
            //FIXME: stop attempting this update
            //try! RTAppDelegate.app().messageAPI.updateMessageLocally(message)
            
            guard let thumbnail = UIImage(data: data) else {
              
              fail(nil)
              
              return
            }
      
            resolve(thumbnail, data.length)
            
          }
          else {
            
            fail(error)
            
          }
          
        }
        
      }
      
      
    }) as? UIImage {
      
      updateImage(thumbnail)
      
    }
    else {
      
      thumbnailImageView.image = UIImage(id: .LocationMap)

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
