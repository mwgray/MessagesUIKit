//
//  UserBadgeView.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import UIKit


public class UserBadgeView: UIView {
  
  public var avatar : UIImage? {
    didSet {
      if avatar != nil {
        initials = nil
      }
      update()
    }
  }
  
  public var initials : String? {
    didSet {
      if initials != nil {
        avatar = nil
      }
      update()
    }
  }

  @IBOutlet weak var initialsLabel : UILabel!
  @IBOutlet weak var avatarImageView : UIImageView!
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    initShared()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    initShared()
  }

  private func initShared() {
    
    snp_makeConstraints { make in
      make.width.equalTo(self.snp_height)
    }

    initialsLabel = UILabel(frame: frame)
    initialsLabel.textColor = UIColor.whiteColor()
    initialsLabel.textAlignment = .Center
    addSubview(initialsLabel)
    
    initialsLabel.snp_makeConstraints { make in
      make.edges.equalTo(self).inset(1)
    }
    
    avatarImageView = UIImageView(frame: frame)
    addSubview(avatarImageView)
    
    avatarImageView.snp_makeConstraints { make in
      make.edges.equalTo(self).inset(1)
    }
    
  }
  
  override public func layoutSubviews() {
    
    let halfHeight = self.frame.size.height/2.0
    
    layer.cornerRadius = halfHeight
    
    initialsLabel.font = initialsLabel.font.fontWithSize(halfHeight * 0.8)

    // Apply oval mask
    let bounds = self.bounds
    let maskLayer = CAShapeLayer()
    maskLayer.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: 1, height: 1)).CGPath
    maskLayer.fillColor = UIColor.blackColor().CGColor
    maskLayer.transform = CATransform3DMakeScale(bounds.size.width, bounds.size.height, 1.0)
    layer.mask = maskLayer
  }
  
  override public var hidden: Bool {
    didSet {
      if hidden {
        NSLayoutConstraint.deactivateConstraints(constraints)
      }
      else {
        NSLayoutConstraint.activateConstraints(constraints)
      }
    }
  }
  
  private func update() {

    if avatar != nil {
      initialsLabel.hidden = true
      avatarImageView.hidden = false
      avatarImageView.image = avatar
    }
    else if initials != nil {
      avatarImageView.hidden = true
      initialsLabel.hidden = false
      initialsLabel.text = initials
    }
    else {
      initialsLabel.hidden = true
      avatarImageView.hidden = false
      avatarImageView.image = UIImage(named:"contact-icon")
    }
    
    setNeedsLayout()
  }
  
}
