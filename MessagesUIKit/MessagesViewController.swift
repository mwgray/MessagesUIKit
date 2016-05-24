//
//  MessagesViewController.swift
//  ReTxt
//
//  Created by Kevin Wooten on 6/20/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import UIKit
import MessagesKit
import CocoaLumberjack


public class MessagesViewController: UICollectionViewController, MessagesViewLayoutDelegate, FetchedResultsControllerDelegate {
  
  public var messageResultsController : FetchedResultsController?
  
  public var showAvatars = false {
    didSet {
      collectionView?.reloadData()
    }
  }
  
  enum Section : Int {
    case Message = 0
    case Status = 1
  }
  
  private let timeHeaderDateFormatter = RelativeHistoryDateFormatter()
  private let recieptFooterDateFormatter = RelativeHistoryDateFormatter()
  
  private var messagesViewLayout : MessagesViewLayout {
    return collectionViewLayout as! MessagesViewLayout
  }
  
  
  private struct UserStatusInfo {
    let user : String
    var status : UserStatus
  }
  private var userStatuses = [UserStatusInfo]()
  
  private var mediaCache = NSCache()
  private var mediaCacheQueue = dispatch_queue_create("MessagesViewController Cache Queue", DISPATCH_QUEUE_SERIAL)
  
  // MARK: View Controller
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    let panner = UIPanGestureRecognizer(target: self, action: #selector(MessagesViewController.panned(_:)))
    panner.delegate = self
    if let nav = navigationController, popper = nav.interactivePopGestureRecognizer {
      panner.requireGestureRecognizerToFail(popper)
    }
    view.addGestureRecognizer(panner)
    
    collectionView!.registerNib(UINib(nibName: "MessagesViewTimeHeader", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.TimeHeader.rawValue, withReuseIdentifier: MessagesViewCellOrnament.TimeHeader.rawValue)
    collectionView!.registerNib(UINib(nibName: "MessagesViewSenderHeader", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.SenderHeader.rawValue, withReuseIdentifier: MessagesViewCellOrnament.SenderHeader.rawValue)
    collectionView!.registerNib(UINib(nibName: "MessagesViewStatusFooter", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.StatusFooter.rawValue, withReuseIdentifier: MessagesViewCellOrnament.StatusFooter.rawValue)
    collectionView!.registerNib(UINib(nibName: "MessagesViewIcon", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.Clarify.rawValue, withReuseIdentifier: MessagesViewCellOrnament.Clarify.rawValue)
    collectionView!.registerNib(UINib(nibName: "MessagesViewActionMenuRight", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.ActionMenu.rawValue, withReuseIdentifier: MessagesViewCellOrnament.ActionMenu.rawValue + "Right")
    collectionView!.registerNib(UINib(nibName: "MessagesViewActionMenuLeft", bundle: NSBundle.muik_frameworkBundle()),
      forSupplementaryViewOfKind: MessagesViewCellOrnament.ActionMenu.rawValue, withReuseIdentifier: MessagesViewCellOrnament.ActionMenu.rawValue + "Left")
    
    messagesViewLayout.cellMargins = UIEdgeInsets(top: 2.5, left: 5, bottom: 2.5, right: 5)
  }
  
  override public func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    //self.collectionView?.setContentOffset(CGPoint(x: 0, y: 3072), animated: true)
  }
  
  override public func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    scrollToLatestItemAnimated(false)
  }
  
  override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animateAlongsideTransition({ context in
      self.collectionView?.reloadData()
    }, completion: { context in
    })
  }
  
  // MARK: Collection View Data Source
  
  func loadSurroundingMessagesAtIndexPath(indexPath: NSIndexPath) -> (Message?, Message, Message?) {
    let message = messageResultsController![indexPath.item] as! Message
    let previousMessage : Message? = indexPath.item > 0 ? messageResultsController?[indexPath.item-1] as? Message : nil
    let nextMessage : Message? = indexPath.item < messageResultsController?.lastIndex() ? messageResultsController?[indexPath.item+1] as? Message : nil
    return (previousMessage, message, nextMessage)
  }

  override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 2
  }
  
  override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    switch Section(rawValue: section)! {
    case .Message:
      return messageResultsController?.numberOfObjects() ?? 0
      
    case .Status:
      return 0
    }

  }
  
  override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    switch Section(rawValue: indexPath.section)! {
    case .Message:
      
      let messageResultsController = self.messageResultsController!
      let message = messageResultsController[indexPath.item] as! Message
      
      let cellId : String
      
      switch message.dynamicType.typeCode() {
      case .Enter, .Exit:
        cellId = "EnterExit"
        
      default:
        cellId = message.dynamicType.typeString()
      }
      
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! MessageCell
      
      if message.sentByMe {
        cell.bubbleView.color = InternalStyle.brandYellow
        cell.bubbleView.quoteStyle = .Down
      }
      else {
        cell.bubbleView.color = InternalStyle.bubbleGray
        cell.bubbleView.quoteStyle = .Up
      }
      
      cell.delegate = self
      
      cell.updateWithMessage(message)
      
      return cell

    case .Status:
      
      let info = userStatuses[indexPath.item]
      
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Status", forIndexPath: indexPath) as! StatusCell
      
      // Update badge
      
      if showAvatars {
        
        cell.badge.hidden = false
        
        let aliasDisplay = AliasDisplayManager.sharedProvider.displayForAlias(info.user)
        cell.badge.initials = aliasDisplay.initials
        cell.badge.avatar = aliasDisplay.avatar
        
      }
      else {
        
        cell.badge.hidden = true
      }
      
      // Update status
      
      switch info.status {
      case .Locating:
        cell.icon.hidden = false
        cell.icon.image = UIImage(named: "location-status")
        
      case .Photographing:
        cell.icon.hidden = false
        cell.icon.image = UIImage(named: "still-camera-status")
        
      case .RecordingAudio:
        cell.icon.hidden = false
        cell.icon.image = UIImage(named: "microphone-status")
        
      case .RecordingVideo:
        cell.icon.hidden = false
        cell.icon.image = UIImage(named: "video-camera-status")
        
      case .SelectingContact:
        cell.icon.hidden = false
        cell.icon.image = UIImage(named: "contact-status")
        
      default:
        cell.icon.hidden = true
      }
      
      return cell
      
    }
    
  }
  
  override public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    
    let view : UICollectionReusableView
    
    if let kind = MessagesViewCellOrnament(rawValue: kind), messageResultsController = messageResultsController {
      
      let message = messageResultsController[indexPath.item] as! Message
      let sentByMe = message.sentByMe
      
      var reuseIdentifer = kind.rawValue
      if kind == .ActionMenu {
        reuseIdentifer += sentByMe ? "Right" : "Left"
      }
      
      view = collectionView.dequeueReusableSupplementaryViewOfKind(kind.rawValue, withReuseIdentifier: reuseIdentifer, forIndexPath: indexPath)
      
      switch kind {
      case .ActionMenu:
        
        let actionMenu = view as! MessagesViewActionMenu
        
        let actionImage : UIImage
        
        if sentByMe {
        
          switch message {
          case is TextMessage:
            actionImage = UIImage(id: .Edit)
            actionMenu.defaultButtonTitle = "Edit"
            
          case is ImageMessage:
            actionImage = UIImage(id: .Edit)
            actionMenu.defaultButtonTitle = "Update"
            
          case is AudioMessage:
            actionImage = UIImage(id: .Audio)
            actionMenu.defaultButtonTitle = "Record"
            
          case is VideoMessage:
            actionImage = UIImage(id: .Video)
            actionMenu.defaultButtonTitle = "Record"
            
          case is LocationMessage:
            actionImage = UIImage(id: .Location)
            actionMenu.defaultButtonTitle = "Update"
            
          case is ContactMessage:
            actionImage = UIImage(id: .Contact)
            actionMenu.defaultButtonTitle = "Update"
            
          case is ConferenceMessage:
            actionImage = UIImage(id: .Phone)
            actionMenu.defaultButtonTitle = "Call back"
            
          default:
            fatalError("invalid message type")
          }
          
        }
        else {

          actionImage = UIImage(id: .Clarify)
          actionMenu.defaultButtonTitle = "Clarify"
          
        }
        
        actionMenu.defaultButton.setImage(actionImage, forState: .Normal)
        
      case .Clarify:
        let icon = view as! MessagesViewIcon
        icon.imageView.image = UIImage(id: sentByMe ? .ClarifyDark : .ClarifyLight)
        
      case .TimeHeader:
        let header = view as! MessagesViewTimeHeader
        header.timeLabel.text = timeHeaderDateFormatter.stringFromDate(message.sent ?? NSDate())
        
      case .SenderHeader:
        let header = view as! MessagesViewSenderHeader
        
        if header.senderAliasDisplay == nil {
          header.senderAliasDisplay = AliasDisplayManager.sharedProvider.displayForAlias(message.sender ?? "")
        }
        
        header.senderBadgeView.initials = header.senderAliasDisplay?.initials
        header.senderBadgeView.avatar = header.senderAliasDisplay?.avatar
        header.senderNameLabel.text = header.senderAliasDisplay?.fullName
        
      case .StatusFooter:
        let footer = view as! MessagesViewStatusFooter
        if message.status == .Unsent {
          footer.statusVerbLabel.text = "Waiting for Internet access"
        }
        else {
          footer.statusVerbLabel.text = message.statusString()
        }
        
        if message.status == .Viewed {
          footer.statusTimeLabel.hidden = false
          footer.statusTimeLabel.text = message.statusTimestamp != nil ? recieptFooterDateFormatter.stringFromDate(message.statusTimestamp!) : "??"
        }
        else {
          footer.statusTimeLabel.hidden = true
        }
        
      default:
        break
      }
      
    }
    else {
      fatalError("Invalid supplementary view")
    }
    
    return view
  }

  override public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    
    switch cell {
    case let messageCell as MessageCell:
      messageCell.willBeginDisplaying()
      
    default:
      break
    }
    
  }
  
  override public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

    switch cell {
    case let messageCell as MessageCell:
      messageCell.didEndDisplaying()
        
    default:
      break
    }
    
  }
  
  // MARK : Collection View (Messages Layout)
  
  func collectionView(collectionView: UICollectionView, messagesLayout: MessagesViewLayout, placementForItemAtIndexPath indexPath: NSIndexPath) -> MessagesViewCellPlacement {

    switch Section(rawValue: indexPath.section)! {
    case .Message:
      
      let message = messageResultsController![indexPath.item] as! Message
      
      if indexPath.item > 5 && indexPath.item < 12 {
        return .Flow
      }
      
      if message.sentByMe {
        return .RightAlign
      }
      else {
        return .LeftAlign
      }
      
    case .Status:
      return .Flow
    }
  }
  
  func collectionView(collectionView: UICollectionView, messagesLayout: MessagesViewLayout, ornamentsForItemAtIndexPath indexPath: NSIndexPath) -> Set<MessagesViewCellOrnament> {
    
    if indexPath.section != Section.Message.rawValue {
      return []
    }

    let (prev, msg, next) = loadSurroundingMessagesAtIndexPath(indexPath)
    let (prevTimeGap, _) = computeTimeGapsWithMessage(msg, prev: prev, next: next)
    
    var ornaments = Set<MessagesViewCellOrnament>()
    
    if actionMenuStates[indexPath] ?? false {
      ornaments.insert(.ActionMenu)
    }
    
    if prevTimeGap {
      ornaments.insert(.TimeHeader)
    }
    
    if msg.sentByMe {
      
      if !(next?.sentByMe ?? false) {
        ornaments.insert(.Quote)
      }
      
      if next == nil {
        ornaments.insert(.StatusFooter)
      }
      
    }
    else {
      
      if msg.sender != prev?.sender ?? "" {
        
        if showAvatars {
          ornaments.insert(.SenderHeader)
        }
        
        ornaments.insert(.Quote)
      }
      
    }
    
    if msg.clarifyFlag {
      ornaments.insert(.Clarify)
    }
    
    return ornaments
  }

  let kMinimumMinutesForGap = 10.0

  func computeTimeGapsWithMessage(message: Message, prev: Message?, next: Message?) -> (Bool, Bool) {

    let prevGap : Bool, nextGap : Bool

    if let msgSent = message.sent {
      if let prevSent = prev?.sent {
        prevGap = msgSent.timeIntervalSinceDate(prevSent) > (60 * kMinimumMinutesForGap)
      }
      else {
        prevGap = true
      }

      if let nextSent = next?.sent {
        nextGap = nextSent.timeIntervalSinceDate(msgSent) > (60 * kMinimumMinutesForGap)
      }
      else {
        nextGap = true
      }
    }
    else {
      prevGap = true
      nextGap = true
    }

    return (prevGap, nextGap)
  }
  
  public func scrollToLatestItemAnimated(animated: Bool) {
    
    if let mrc = messageResultsController {
      let lastIndexPath = NSIndexPath(forItem: mrc.lastIndex(), inSection: 0)
      collectionView!.scrollToItemAtIndexPath(lastIndexPath, atScrollPosition: .Bottom, animated: animated)
    }
  }
  
  public func updateInsets(insets: UIEdgeInsets) {
    
    //collectionView!.contentInset = insets
    //collectionView!.scrollIndicatorInsets = insets
    
//    if let editingIndex = editingIndexPath {
//      [self _scrollToItemAtIndexPath:_editingIndexPath animated:YES]
//    }
  }
  
  // MARK: Menu support
  
  override public func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return indexPath.section == 0
  }
  
  override public func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return true
  }
  
  override public func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    print("perform", action)
  }
  
  private var actionMenuStates = [NSIndexPath: Bool]()
  private var actionMenuDragTarget : NSIndexPath?
  
  func beginInteractiveActionMenuDraggingForItemAtIndexPath(indexPath: NSIndexPath) {
    
    let layout = collectionViewLayout as! MessagesViewLayout
    
    let context = layout.invalidationContextForInteractivelyDraggingActionMenuAtIndexPath(indexPath)
    layout.invalidateLayoutWithContext(context)
    
    actionMenuDragTarget = indexPath
  }
  
  func updateInteractiveActionMenuDragDistance(distance: CGFloat) {
    
    guard let actionMenuDragTarget = actionMenuDragTarget else {
      return
    }
    
    let layout = collectionViewLayout as! MessagesViewLayout
    let itemLayoutAttrs = collectionViewLayout.layoutAttributesForItemAtIndexPath(actionMenuDragTarget) as! MessagesViewLayoutAttributes
    
    let distanceFix = CGFloat(itemLayoutAttrs.placement ?? .RightAlign == .RightAlign ? -1 : 1)
    
    let context = layout.invalidationContextForInteractivelyDraggingActionMenuAtIndexPath(actionMenuDragTarget)
    context.interactiveActionMenuDragDistance = distance * distanceFix
    layout.invalidateLayoutWithContext(context)
  }
  
  func endInteractiveActionMenuDraggingWithDistance(distance: CGFloat, velocity: CGFloat) {
    
    guard let actionMenuDragTarget = actionMenuDragTarget else {
      return
    }
    
    let layout = collectionViewLayout as! MessagesViewLayout
    let itemLayoutAttrs = collectionViewLayout.layoutAttributesForItemAtIndexPath(actionMenuDragTarget) as! MessagesViewLayoutAttributes
    
    let distanceFix = CGFloat(itemLayoutAttrs.placement ?? .RightAlign == .RightAlign ? -1 : 1)

    let context = layout.invalidationContextForEndingInteractiveDraggingOfActionMenuAtIndexPath(actionMenuDragTarget)
    
    let menuDistance = actionMenuStates[actionMenuDragTarget] ?? false ? context.interactiveActionMenuDragActionMenuSize?.width ?? 0 : 0
    let totalDistance = distance + (menuDistance * distanceFix)

    let targetDistance = distance + (velocity * 0.3)
    let totalTargetDistance = targetDistance + (menuDistance * distanceFix)
    
    let openThreshold = (context.interactiveActionMenuDragActionMenuSize?.width ?? 0) * 0.7
    let quickThreshold = (context.interactiveActionMenuDragActionMenuSize?.width ?? 0) * 1.75
    
    actionMenuStates[actionMenuDragTarget] = (totalTargetDistance * distanceFix) > openThreshold && (totalDistance * distanceFix) < quickThreshold
    
    self.collectionView!.performBatchUpdates({
      
      layout.invalidateLayoutWithContext(context)
      
    }, completion: nil)

    self.actionMenuDragTarget = nil
  }
  
  func cancelInteractiveActionMenuDragging() {

    guard let actionMenuDragTarget = actionMenuDragTarget else {
      return
    }
    
    let layout = collectionViewLayout as! MessagesViewLayout
    
    let context = MessagesViewLayoutInvalidationContext()
    context.invalidateItemsAtIndexPaths([actionMenuDragTarget])
    layout.invalidateLayoutWithContext(context)
    
    self.actionMenuDragTarget = nil
  }
  
}


extension MessagesViewController : UIGestureRecognizerDelegate {

  
  public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      
      let location = pan.locationInView(collectionView!)

      return collectionView!.indexPathForItemAtPoint(location) != nil
    }
    
    return true
  }

  
  func panned(sender: UIPanGestureRecognizer) {
    
    switch sender.state {
    case .Began:

      let location = sender.locationInView(collectionView)
      
      guard let target = collectionView!.indexPathForItemAtPoint(location) else {
        break
      }

      beginInteractiveActionMenuDraggingForItemAtIndexPath(target)
    
    case .Changed:
      
      let distance = sender.translationInView(collectionView).x
      updateInteractiveActionMenuDragDistance(distance)
      
    case .Ended:
      
      let distance = sender.translationInView(collectionView).x
      let velocity = sender.velocityInView(collectionView).x
      
      endInteractiveActionMenuDraggingWithDistance(distance, velocity: velocity)
      
    case .Cancelled, .Failed:
      
      cancelInteractiveActionMenuDragging()
      
    default:
      break
    }
    
  }
  
}



extension MessagesViewController : MessageCellDelegate {
  
  public func loadCachedMediaForKey(key: AnyObject, loader: (resolved: (AnyObject, Int) -> Void, failed: (NSError?) -> Void) -> Void) -> AnyObject? {
    
    var cached : AnyObject?
    
    mediaCacheQueue.sync {

      cached = self.mediaCache.objectForKey(key)
      if cached == nil {
        self.mediaCache.setObject(NSNull(), forKey: key, cost: 0)
      }
      
    }
    
    // NSNull is the signal that a load is in progress
    if cached is NSNull {
      return nil
    }
    else if cached != nil {
      return cached
    }
    
    
    GCD.userInitiatedQueue.async {
      
      loader(resolved: { object, cost in
      
        self.mediaCacheQueue.async {
          self.mediaCache.setObject(object, forKey: key, cost: cost)
        }
        
        var info : [String: AnyObject] = [MessageCellMediaDataAvailableNotificationMediaIdKey: key]
        
        switch object {
        case is UIImage, is AnimatedImage:
          info[MessageCellMediaDataAvailableNotificationImage] = object
          
        case let audioFile as AudioFile:
          info[MessageCellMediaDataAvailableNotificationAudio] = audioFile
          
        default:
          break
        }
        
        let notification = NSNotification(name: MessageCellMediaDataAvailableNotification, object: key, userInfo: info)
        
        GCD.mainQueue.async {
          NSNotificationCenter.defaultCenter().postNotification(notification)
        }
        
      }, failed: { error in
        
        GCD.mainQueue.async {
          NSNotificationCenter.defaultCenter().postNotificationName(MessageCellMediaDataAvailableNotification, object: key)
        }
        
      })
      
    }
    
    return nil
  }
  
}



extension MessagesViewController : AudioMessageCellDelegate {
  
  public func checkAudioPlayingWithKey(key: String) -> Bool {
    return false
  }
  
  public func progressOfAudioPlayingWithKey(key: String) -> CGFloat {
    return 0
  }
  
}



class MessagesViewActionMenu : UICollectionReusableView {
  
  @IBInspectable var defaultButtonTitle : String?
  @IBOutlet var defaultButton : UIButton!
  @IBOutlet var otherButton : UIButton!
  @IBOutlet var quickEnabledConstraint : NSLayoutConstraint?
  
  private var minSize : CGSize!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    minSize = systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
  }
  
  override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
    
    super.applyLayoutAttributes(layoutAttributes)

    // Always calculate size without text
    let quickActive = layoutAttributes.size.width > (minSize.width * 1.75)
    
    if quickActive != quickEnabledConstraint?.active {

      quickEnabledConstraint?.active = quickActive
      defaultButton.setTitle(quickActive ? defaultButtonTitle : nil, forState: .Normal)
      
      UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 3, options: [.AllowUserInteraction], animations: {
        
        self.layoutIfNeeded()
        
      }, completion: nil)
      
      
    }
    
  }
  
}


class MessagesViewIcon : AutoLayoutCollectionReusableView {
  
  @IBOutlet var imageView : UIImageView!
  
}

class MessagesViewTimeHeader : AutoLayoutCollectionReusableView {

  @IBOutlet var timeLabel : UILabel!
  
}

class MessagesViewSenderHeader : AutoLayoutCollectionReusableView {

  var senderAliasDisplay : AliasDisplay?
  
  @IBOutlet var senderBadgeView : UserBadgeView!
  @IBOutlet var senderNameLabel : UILabel!
  
}

class MessagesViewStatusFooter : AutoLayoutCollectionReusableView {
  
  @IBOutlet var statusVerbLabel : UILabel!
  @IBOutlet var statusTimeLabel : UILabel!
  
}
