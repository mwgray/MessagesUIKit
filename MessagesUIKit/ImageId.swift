//
//  ImageIds.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/17/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


struct ImageId {

  enum ActionIcon : String {
    case Clarify = "action-icon-clarify"
    case Delete = "action-icon-delete"
    case Edit = "action-icon-update"
    case Image = "action-icon-image"
    case Video = "action-icon-video"
    case Phone = "action-icon-phone"
    case Contact = "action-icon-contact"
    case Location = "action-icon-location"
  }
  
  enum ActionButtonBackground : String {
    case Gray = "action-button-bg-gray"
    case Black = "action-button-bg-black"
    case Red = "action-button-bg-red"
  }
  
  enum MessageViewIcon : String {
    case ClarifyLight = "clarify-light"
    case ClarifyDark = "clarify-dark"
  }

  enum MessageButton : String {
    case AudioPlay = "audio-play"
    case AudioPause = "audio-pause"
  }
  
  enum Placeholder : String {
    case LocationMap = "location-map"
    case ImageError = "image-load-error"
    case VideoError = "video-load-error"
  }
  
}


extension UIImage {
  
  convenience init(id: ImageId.ActionIcon) {
    self.init(named: id.rawValue, inBundle: NSBundle.muik_frameworkBundle(), compatibleWithTraitCollection: nil)!
  }
  
  convenience init(id: ImageId.ActionButtonBackground) {
    self.init(named: id.rawValue, inBundle: NSBundle.muik_frameworkBundle(), compatibleWithTraitCollection: nil)!
  }
  
  convenience init(id: ImageId.MessageViewIcon) {
    self.init(named: id.rawValue, inBundle: NSBundle.muik_frameworkBundle(), compatibleWithTraitCollection: nil)!
  }
  
  convenience init(id: ImageId.MessageButton) {
    self.init(named: id.rawValue, inBundle: NSBundle.muik_frameworkBundle(), compatibleWithTraitCollection: nil)!
  }
  
  convenience init(id: ImageId.Placeholder) {
    self.init(named: id.rawValue, inBundle: NSBundle.muik_frameworkBundle(), compatibleWithTraitCollection: nil)!
  }
  
}
