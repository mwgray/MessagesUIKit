//
//  ChatToolBarView.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/24/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public enum ChatToolBarViewPlaybackMode : Int32 {
  case New
  case Recording
  case Playing
  case Paused
  case Stopped
}

//FIXME: implement
public class WaveformView : UIView {
  
}

@objc public protocol ChatToolBarViewDelegate {
  
  optional func chatToolBarViewDidStartTyping(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidEndTyping(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudio(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewBeganPressingAudio(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewEndedPressingAudio(chatToolBarView: ChatToolBarView, flicked: Bool)
  
  optional func chatToolBarViewCanceledPressingAudio(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackPlay(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackPause(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackCancel(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackReset(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackRecord(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackStop(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapAudioPlaybackSend(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideo(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewBeganPressingVideo(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewEndedPressingVideo(chatToolBarView: ChatToolBarView, flicked: Bool)
  
  optional func chatToolBarViewCanceledPressingVideo(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackPlay(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackPause(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackCancel(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackReset(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackRecord(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackStop(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapVideoPlaybackSend(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapCamera(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewBeganPressingCamera(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewEndedPressingCamera(chatToolBarView: ChatToolBarView, flicked: Bool)
  
  optional func chatToolBarViewCanceledPressingCamera(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapLocation(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapContact(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidTapSend(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewWillShowButtons(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidShowButtons(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewWillHideButtons(chatToolBarView: ChatToolBarView)
  
  optional func chatToolBarViewDidHideButtons(chatToolBarView: ChatToolBarView)
  
}



let kMinimumDistanceForFlick = CGFloat(30.0)
let kWaveformHeight = CGFloat(45.0)



public class ChatToolBarView: UIView, UITextViewDelegate {
  
  public var enabled: Bool = false {
    didSet {
      updateButtons()
    }
  }
  
  private var buttonsAreVisible = false
  
  @IBOutlet private weak var internalView: UIView!
  @IBOutlet private weak var cameraButton: UIButton!
  @IBOutlet private weak var videoButton: UIButton!
  @IBOutlet private weak var audioButton: UIButton!
  @IBOutlet private weak var contactButton: UIButton!
  @IBOutlet private weak var locationButton: UIButton!
  @IBOutlet private weak var sendButton: UIButton!
  @IBOutlet private weak var menuButton: UIButton!
  @IBOutlet private weak var textView: MessageTextView!
  @IBOutlet private weak var textViewTapGesture: UITapGestureRecognizer!
  @IBOutlet private weak var waveformView: WaveformView!
  @IBOutlet private weak var audioPlaybackView: UIView!
  @IBOutlet private weak var audioPlaybackInfoLabel: UILabel!
  @IBOutlet private weak var audioPlaybackPlotView: AudioPlot!
  @IBOutlet private weak var audioPlaybackTimeView: UILabel!
  @IBOutlet private weak var audioPlaybackPlayButton: UIButton!
  @IBOutlet private weak var audioPlaybackPauseButton: UIButton!
  @IBOutlet private weak var audioPlaybackRecordButton: UIButton!
  @IBOutlet private weak var audioPlaybackStopButton: UIButton!
  @IBOutlet private weak var audioPlaybackCancelButton: UIButton!
  @IBOutlet private weak var audioPlaybackResetButton: UIButton!
  @IBOutlet private weak var videoPlaybackView: UIView!
  @IBOutlet private weak var videoPlaybackProgressView: UIProgressView!
  @IBOutlet private weak var videoPlaybackTimeView: UILabel!
  @IBOutlet private weak var videoPlaybackPlayButton: UIButton!
  @IBOutlet private weak var videoPlaybackPauseButton: UIButton!
  @IBOutlet private weak var videoPlaybackRecordButton: UIButton!
  @IBOutlet private weak var videoPlaybackStopButton: UIButton!
  @IBOutlet private weak var videoPlaybackCancelButton: UIButton!
  @IBOutlet private weak var videoPlaybackResetButton: UIButton!
  
  // Constraints
  private var showButtonsConstraints: [Constraint]!
  private var hideButtonsConstraints: [Constraint]!
  private var textViewHeightConstraint: Constraint!
  private var waveformViewHeightConstraint: Constraint!
  
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    load()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    load()
  }
  
  func load() {
    
    let nib: UINib = UINib(nibName: "ChatToolBarView", bundle: NSBundle.muik_frameworkBundle())
    nib.instantiateWithOwner(self, options: nil)
    
    internalView.frame = bounds
    addSubview(internalView)
    
    internalView.snp_makeConstraints { make in
      make.edges.equalTo(self.snp_edges)
    }
    
    audioPlaybackView.hidden = true
    audioPlaybackView.frame = bounds
    audioPlaybackView.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
    addSubview(audioPlaybackView)
    
    enabled = true
    internalView.backgroundColor = UIColor.clearColor()
    //FIXME: applyUITextFieldBorder(textView)
    //FIXME: applyBlurBackground(internalView)
    //FIXME: addBorders(internalView, UIEdgeInsetsMake(0.5, 0, 0, 0), RTStyle.brandGray())
    
    buildConstraints()
    
    showButtonsConstraints.forEach { $0.activate() }
    buttonsAreVisible = true
    
    textView.layoutManager.allowsNonContiguousLayout = false
  }
  
  deinit {
    delegate = nil
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  
  var currentMessages: [AnyObject] {
    get {
      
      // Execute auto-correct (for better or worse lol)
      textView.inputDelegate?.selectionWillChange(textView)
      textView.inputDelegate?.selectionDidChange(textView)
      
      var messages = [AnyObject]()
      var currentText = ""
      
      textView.textStorage.enumerateAttributesInRange(NSMakeRange(0, textView.textStorage.length), options: []) { attrs, range, stop in
      
        if let attachment = attrs[NSAttachmentAttributeName] as? NSTextAttachment {

          let messageText = currentText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
          if !messageText.isEmpty {
            messages.append(messageText)
            currentText = ""
          }
          
          if let image = attachment.image {
            messages.append(image)
          }

        }
        else {
          let text = self.textView.textStorage.string as NSString
          currentText += text.substringWithRange(range)
        }
        
      }
      
      let messageText = currentText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
      if !messageText.isEmpty {
        messages.append(messageText)
      }
      return messages
    }
    
    set(currentMessages) {
      
      let currentText = NSMutableAttributedString()
      
      for message: AnyObject in currentMessages {
        
        switch message {
        case let messageText as String:
          currentText.appendAttributedString(textView.attributedTextForString(messageText))
          
        case let messageAttributedText as NSAttributedString:
          currentText.appendAttributedString(textView.attributedTextForString(messageAttributedText.string))
          
        case let messageImage as UIImage:
          currentText.appendAttributedString(textView.attributedTextForImage(messageImage))
          
        default:
          break
        }
      }
      
      textView.attributedText = currentText
      
      updateButtons()
      
      if !buttonsAreVisible {
        adjustTextViewHeight()
      }
      
    }
  }
  
  var hasCurrentMessages: Bool {
    get {
      return textView.textStorage.length > 0
    }
  }
  
  @IBOutlet weak var delegate: ChatToolBarViewDelegate!
  
  
  @IBAction func hideToolBarButtons() {
    textView.becomeFirstResponder()
    _hideToolBarButtons()
  }
  
  @IBAction func showToolBarButtons() {
    _showToolBarButtons()
  }
  
  func showWaveformView() {
    waveformView.hidden = false
    waveformViewHeightConstraint.updateOffset(kWaveformHeight)
    animateWithDuration(0.2) {
      self.superview?.layoutIfNeeded()
    }
  }
  
  func hideWaveformView() {
    waveformViewHeightConstraint.updateOffset(0)
    animateWithDuration(0.2) {
      self.superview?.layoutIfNeeded()
    }
  }
  
  func updateWaveformView(level: CGFloat) {
    if waveformView.hidden {
      return
    }
    //FIXME: waveformView.updateWithLevel(level)
    setNeedsDisplay()
  }
  
  func audioPlaybackControlsShowing() -> Bool {
    return !audioPlaybackView.hidden
  }
  
  func showAudioPlaybackControls() {
    audioPlaybackView.alpha = 0
    audioPlaybackView.hidden = false
    animateWithDuration(0.2, animations: {() -> Void in
      self.audioPlaybackView.alpha = 1
    })
  }
  
  func hideAudioPlaybackControls() {
    audioPlaybackView.alpha = 1
    animateWithDuration(0.2, animations: {() -> Void in
        self.audioPlaybackView.alpha = 0
      }, completion: {(finished: Bool) -> Void in
        // This ensures the blurry toolbar refreshes its blurriness
        self.internalView.subviews.forEach { subview in
          subview.setNeedsDisplay()
        }
        if finished {
          self.audioPlaybackView.hidden = true
        }
    })
  }
  
  func updateAudioPlaybackDataWithTime(duration: NSTimeInterval, samples: UnsafePointer<Float>, count sampleCount: UInt) {
    let seconds = Int(duration)
    audioPlaybackTimeView.text = "\(seconds / 60):\(seconds % 60)"
    audioPlaybackPlotView.updateSamples(samples, sampleCount: sampleCount)
  }
  
  func updateAudioPlaybackPlayProgress(progress: CGFloat) {
    audioPlaybackPlotView.progress = progress
  }
  
  func updateAudioPlaybackMode(mode: ChatToolBarViewPlaybackMode) {
    switch mode {
    case .New:
      audioPlaybackPlotView.hidden = true
      audioPlaybackTimeView.hidden = true
      audioPlaybackRecordButton.hidden = false
      audioPlaybackStopButton.hidden = true
      audioPlaybackPlayButton.hidden = true
      audioPlaybackPauseButton.hidden = true
      audioPlaybackCancelButton.hidden = false
      audioPlaybackResetButton.hidden = true
    case .Paused, .Stopped:
      audioPlaybackPlotView.hidden = false
      audioPlaybackTimeView.hidden = false
      audioPlaybackRecordButton.hidden = true
      audioPlaybackStopButton.hidden = true
      audioPlaybackPlayButton.hidden = false
      audioPlaybackPauseButton.hidden = true
      audioPlaybackCancelButton.hidden = false
      audioPlaybackResetButton.hidden = false
    case .Playing:
      audioPlaybackPlotView.hidden = false
      audioPlaybackTimeView.hidden = false
      audioPlaybackRecordButton.hidden = true
      audioPlaybackStopButton.hidden = true
      audioPlaybackPlayButton.hidden = true
      audioPlaybackPauseButton.hidden = false
      audioPlaybackCancelButton.hidden = false
      audioPlaybackResetButton.hidden = false
    case .Recording:
      audioPlaybackPlotView.hidden = true
      audioPlaybackTimeView.hidden = true
      audioPlaybackRecordButton.hidden = true
      audioPlaybackStopButton.hidden = false
      audioPlaybackPlayButton.hidden = true
      audioPlaybackPauseButton.hidden = true
      audioPlaybackCancelButton.hidden = false
      audioPlaybackResetButton.hidden = false
    }
    
  }
  
  func videoPlaybackControlsShowing() -> Bool {
    return !videoPlaybackView.hidden
  }
  
  func showVideoPlaybackControls() {
    videoPlaybackView.alpha = 0
    videoPlaybackView.hidden = false
    animateWithDuration(0.2, animations: {() -> Void in
      self.videoPlaybackView.alpha = 1
    })
  }
  
  func hideVideoPlaybackControls() {
    animateWithDuration(0.2, animations: {
      self.videoPlaybackView.alpha = 0
    }, completion: { finished in
      // This ensures the blurry toolbar refreshes its blurriness
      self.internalView.subviews.forEach {subview in
        subview.setNeedsDisplay()
      }
      self.videoPlaybackView.hidden = true
    })
  }
  
  func updateVideoPlaybackDataWithTime(duration: NSTimeInterval) {
    let seconds = Int(duration)
    videoPlaybackTimeView.text = "\(seconds / 60):\(seconds % 60)"
  }
  
  func updateVideoPlaybackPlayProgress(progress: Float) {
    videoPlaybackProgressView.progress = progress
  }
  
  func updateVideoPlaybackMode(mode: ChatToolBarViewPlaybackMode) {
    switch mode {
    case .New:
      videoPlaybackProgressView.hidden = true
      videoPlaybackTimeView.hidden = true
      videoPlaybackRecordButton.hidden = false
      videoPlaybackStopButton.hidden = true
      videoPlaybackPlayButton.hidden = true
      videoPlaybackPauseButton.hidden = true
      videoPlaybackCancelButton.hidden = false
      videoPlaybackResetButton.hidden = true
    case .Paused, .Stopped:
      videoPlaybackProgressView.hidden = false
      videoPlaybackTimeView.hidden = false
      videoPlaybackRecordButton.hidden = true
      videoPlaybackStopButton.hidden = true
      videoPlaybackPlayButton.hidden = false
      videoPlaybackPauseButton.hidden = true
      videoPlaybackCancelButton.hidden = false
      videoPlaybackResetButton.hidden = false
    case .Playing:
      videoPlaybackProgressView.hidden = false
      videoPlaybackTimeView.hidden = false
      videoPlaybackRecordButton.hidden = true
      videoPlaybackStopButton.hidden = true
      videoPlaybackPlayButton.hidden = true
      videoPlaybackPauseButton.hidden = false
      videoPlaybackCancelButton.hidden = false
      videoPlaybackResetButton.hidden = false
    case .Recording:
      videoPlaybackProgressView.hidden = true
      videoPlaybackTimeView.hidden = true
      videoPlaybackRecordButton.hidden = true
      videoPlaybackStopButton.hidden = false
      videoPlaybackPlayButton.hidden = true
      videoPlaybackPauseButton.hidden = true
      videoPlaybackCancelButton.hidden = false
      videoPlaybackResetButton.hidden = false
    }
    
  }
  
  func buildConstraints() {
    sendButton.snp_makeConstraints { make in
      make.centerY.equalTo(self.menuButton.snp_centerY)
    }
    waveformView.snp_makeConstraints { make in
      make.bottom.equalTo(self.textView.snp_top).offset(-5)
      make.top.equalTo(self.snp_top)
      make.leading.equalTo(self.snp_leading)
      make.trailing.equalTo(self.snp_trailing)
      self.waveformViewHeightConstraint = make.height.equalTo(0).priorityHigh().constraint
    }
    
    textView.snp_makeConstraints { make in
      make.bottom.equalTo(self.snp_bottom).offset(-5)
    }
    
    menuButton.snp_makeConstraints { make in
      make.bottom.equalTo(self.snp_bottom)
      make.bottom.equalTo(self.cameraButton.snp_bottom)
      make.bottom.equalTo(self.videoButton.snp_bottom)
      make.bottom.equalTo(self.audioButton.snp_bottom)
      make.bottom.equalTo(self.locationButton.snp_bottom)
      make.bottom.equalTo(self.contactButton.snp_bottom)
      make.leading.equalTo(self.snp_leading)
      make.size.equalTo(self.menuButton.frame.size).priorityHigh()
      make.size.equalTo(self.cameraButton)
      make.size.equalTo(self.videoButton)
      make.size.equalTo(self.audioButton)
      make.size.equalTo(self.locationButton)
      make.size.equalTo(self.contactButton)
    }
    
    hideButtonsConstraints = [Constraint]()
    hideButtonsConstraints.appendContentsOf(snp_prepareConstraints { make in
      make.leading.equalTo(self.cameraButton.snp_leading)
      make.leading.equalTo(self.videoButton.snp_leading)
      make.leading.equalTo(self.audioButton.snp_leading)
      make.leading.equalTo(self.locationButton.snp_leading)
      make.leading.equalTo(self.contactButton.snp_leading)
    })
    hideButtonsConstraints.appendContentsOf(textView.snp_prepareConstraints { make in
      make.leading.equalTo(self.menuButton.snp_trailing).offset(5)
      make.height.lessThanOrEqualTo(120)
      self.textViewHeightConstraint = make.height.equalTo(self.textView.frame.size.height).priority(999).constraint
    })
    hideButtonsConstraints.appendContentsOf(sendButton.snp_prepareConstraints { make in
      make.leading.equalTo(self.textView.snp_trailing).offset(8)
      make.trailing.equalTo(self.snp_trailing).offset(-8)
    })
    hideButtonsConstraints.forEach { $0.deactivate() }
    
    showButtonsConstraints = [Constraint]()
    showButtonsConstraints.appendContentsOf(cameraButton.snp_prepareConstraints { make in
      make.leading.equalTo(self.snp_leading)
    })
    showButtonsConstraints.appendContentsOf(videoButton.snp_prepareConstraints { make in
      make.leading.equalTo(self.cameraButton.snp_trailing)
      make.trailing.equalTo(self.audioButton.snp_leading)
    })
    showButtonsConstraints.appendContentsOf(contactButton.snp_prepareConstraints { make in
      make.leading.equalTo(self.audioButton.snp_trailing)
      make.trailing.equalTo(self.locationButton.snp_leading)
    })
    showButtonsConstraints.appendContentsOf(locationButton.snp_prepareConstraints { make in
      make.trailing.equalTo(self.textView.snp_leading).offset(5)
    })
    showButtonsConstraints.appendContentsOf(textView.snp_prepareConstraints { make in
      make.trailing.equalTo(self.snp_trailing).offset(-5)
      make.height.equalTo(self.textView.frame.size.height)
      make.width.lessThanOrEqualTo(self.snp_width).dividedBy(3)
    })
    showButtonsConstraints.appendContentsOf(sendButton.snp_prepareConstraints { make in
      make.leading.equalTo(self.snp_trailing)
    })
  }
  
  public override func intrinsicContentSize() -> CGSize {
    let size = internalView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    return size
  }
  
  func scrollToEndFix() {
    let contentSize: CGSize = textView.contentSize
    self.textView.scrollRectToVisible(CGRectMake(0, 0, contentSize.width, contentSize.height), animated: false)
  }
  
  func animateWithDuration(duration: NSTimeInterval, animations: () -> Void) {
    animateWithDuration(duration, animations: animations, completion: nil)
  }

  func animateWithDuration(duration: NSTimeInterval, animations: () -> Void, completion: ((Bool) -> Void)?) {
    UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: animations, completion: completion)
  }
  
  func adjustTextViewHeight() {
    if buttonsAreVisible {
      _hideToolBarButtons()
      return
    }
    let textHeight: CGFloat = textView.sizeThatFits(CGSizeMake(textView.frame.size.width, 0)).height
    textViewHeightConstraint.updateOffset(textHeight)
    invalidateIntrinsicContentSize()
    superview?.layoutIfNeeded()
    scrollToEndFix()
  }
  
  func updateButtons() {
    sendButton.enabled = enabled && !textView.text.isEmpty
    cameraButton.enabled = enabled
    videoButton.enabled = enabled
    audioButton.enabled = enabled
    locationButton.enabled = enabled
    contactButton.enabled = enabled
  }
  
  func _showToolBarButtons() {
    if buttonsAreVisible {
      return
    }
    textViewTapGesture.enabled = true
    hideButtonsConstraints.forEach { $0.deactivate() }
    showButtonsConstraints.forEach { $0.activate() }
    delegate.chatToolBarViewWillShowButtons?(self)
    animateWithDuration(0.2, animations: {() -> Void in
      self.cameraButton.alpha = 1
      self.videoButton.alpha = 1
      self.audioButton.alpha = 1
      self.contactButton.alpha = 1
      self.locationButton.alpha = 1
      self.menuButton.alpha = 0
      self.sendButton.alpha = 0
      self.superview?.layoutIfNeeded()
      }, completion: { finished in
        self.delegate.chatToolBarViewDidShowButtons?(self)
    })
    self.buttonsAreVisible = true
  }
  
  func _hideToolBarButtons() {
    if !self.buttonsAreVisible {
      return
    }
    // Remove & save any current position animations (in case the keyboard is
    //  sliding up)
    let positionAnim = layer.animationForKey("position")
    layer.removeAnimationForKey("position")

    textViewTapGesture.enabled = false
    showButtonsConstraints.forEach { $0.deactivate() }
    hideButtonsConstraints.forEach { $0.activate() }
    delegate.chatToolBarViewWillHideButtons?(self)
    
    self.animateWithDuration(0.2, animations: {
      self.cameraButton.alpha = 0
      self.videoButton.alpha = 0
      self.audioButton.alpha = 0
      self.contactButton.alpha = 0
      self.locationButton.alpha = 0
      self.menuButton.alpha = 1
      self.sendButton.alpha = 1
      self.superview?.layoutIfNeeded()
      }, completion: { finished in
        self.delegate.chatToolBarViewDidHideButtons?(self)
    })
    // Add back the previous position animation as an extra animation
    if let positionAnim = positionAnim {
      layer.addAnimation(positionAnim, forKey: "position-prev")
    }
    buttonsAreVisible = false
    textView.selectedRange = NSMakeRange(textView.text.characters.count, 0)
    updateButtons()
  }
  
  public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
    hideAudioPlaybackControls()
    hideWaveformView()
    return true
  }
  
  public func textViewDidBeginEditing(textView: UITextView) {
    _hideToolBarButtons()
  }
  
  public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
    
    if buttonsAreVisible {
      _hideToolBarButtons()
    }
    
    let oldText: NSString = textView.text!
    let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: text)
    
    if oldText.length == 0 && newText.length > 0 {
      delegate.chatToolBarViewDidStartTyping?(self)
    }
    else if oldText.length > 0 && newText.length == 0 {
      delegate.chatToolBarViewDidEndTyping?(self)
    }
    
    return true
  }
  
  public func textViewDidChange(textView: UITextView) {
    adjustTextViewHeight()
    updateButtons()
  }
  
  public func textViewShouldEndEditing(textView: UITextView) -> Bool {
    hideAudioPlaybackControls()
    hideWaveformView()
    showToolBarButtons()
    return true
  }
  
  @IBAction func cameraTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapCamera?(self)
  }
  
  @IBAction func cameraPressed(gr: UILongPressGestureRecognizer) {
    
    switch gr.state {
    case .Began:
      delegate.chatToolBarViewBeganPressingCamera?(self)
      
    case .Ended:
      let pt: CGPoint = gr.locationInView(cameraButton)
      let flicked: Bool = pt.y < -kMinimumDistanceForFlick
      delegate.chatToolBarViewEndedPressingCamera?(self, flicked: flicked)
      
    case .Cancelled, .Failed:
      delegate.chatToolBarViewCanceledPressingCamera?(self)
      
    default:
      break
    }
    
  }
  
  @IBAction func audioTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudio?(self)
  }
  
  @IBAction func audioPressed(gr: UIGestureRecognizer) {
    switch gr.state {
    case .Began:
      delegate.chatToolBarViewBeganPressingAudio?(self)
      
    case .Ended:
      let pt: CGPoint = gr.locationInView(audioButton)
      let flicked: Bool = pt.y < -kMinimumDistanceForFlick
      delegate.chatToolBarViewEndedPressingAudio?(self, flicked: flicked)
      
    case .Cancelled, .Failed:
      delegate.chatToolBarViewCanceledPressingAudio?(self)
      
    default:
      break
    }
    
  }
  
  @IBAction func videoTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideo?(self)
  }
  
  @IBAction func videoPressed(gr: UIGestureRecognizer) {

    switch gr.state {
    case .Began:
      delegate.chatToolBarViewBeganPressingVideo?(self)
      
    case .Ended:
      let pt: CGPoint = gr.locationInView(videoButton)
      let flicked: Bool = pt.y < -kMinimumDistanceForFlick
      delegate.chatToolBarViewEndedPressingVideo?(self, flicked: flicked)
      
    case .Cancelled, .Failed:
      delegate.chatToolBarViewCanceledPressingVideo?(self)
      
    default:
      break
    }
    
  }
  
  @IBAction func contactTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapContact?(self)
  }
  
  @IBAction func locationTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapLocation?(self)
  }
  
  @IBAction func sendTapped(sender: AnyObject) {
    delegate.chatToolBarViewDidTapSend?(self)
    currentMessages = []
  }
  
  @IBAction func audioPlay(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackPlay?(self)
  }
  
  @IBAction func audioPause(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackPause?(self)
  }
  
  @IBAction func audioCancel(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackCancel?(self)
  }
  
  @IBAction func audioReset(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackReset?(self)
  }
  
  @IBAction func audioRecord(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackRecord?(self)
  }
  
  @IBAction func audioStop(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackStop?(self)
  }
  
  @IBAction func audioSend(sender: AnyObject) {
    delegate.chatToolBarViewDidTapAudioPlaybackSend?(self)
  }
  
  @IBAction func videoPlay(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackPlay?(self)
  }
  
  @IBAction func videoPause(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackPause?(self)
  }
  
  @IBAction func videoCancel(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackCancel?(self)
  }
  
  @IBAction func videoReset(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackReset?(self)
  }
  
  @IBAction func videoRecord(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackRecord?(self)
  }
  
  @IBAction func videoStop(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackStop?(self)
  }
  
  @IBAction func videoSend(sender: AnyObject) {
    delegate.chatToolBarViewDidTapVideoPlaybackSend?(self)
  }
  
}
