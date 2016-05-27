//
//  ChatViewController.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 9/22/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import TURecipientBar
import CocoaLumberjack
import MobileCoreServices
import MessageUI
import MessagesKit
import PSOperations
import AssetsLibrary
import AddressBookUI
import CoreLocation



@objc public class PickContactOperation : Operation {
  
  public var contact : Contact?
  
}

@objc public class PickImageOperation : Operation {
  
  public var image : NSInputStream?
  
}

@objc public protocol ChatViewControllerDelegate {
  
  optional func chatViewController(chatViewController: ChatViewController, wantsRecipientForContact contact: Contact) -> ChatRecipient?
  optional func chatViewController(chatViewController: ChatViewController, wantsRecipientForProposedAlias proposedAlias: String) -> ChatRecipient?
  
  optional func chatViewControllerRequestedPickContactOperation(chatViewController: ChatViewController) -> PickContactOperation
  optional func chatViewControllerRequestedPickImageOperation(chatViewController: ChatViewController) -> PickImageOperation
  
}



enum MessageData {
  case Text(String)
  case Image(NSURL?, UIImage?, [String: AnyObject]?)
  case Audio(NSURL)
  case Video(NSURL)
  case Contact(ABRecord)
  case Location(CLLocation)
}



public class ChatViewController: UIViewController {
  
  
  let insetPadding = CGFloat(5)
  
  
  public var chat : Chat? {
    didSet {
      GCD.mainQueue.async { self.updateChat() }
    }
  }

  public var messageAPI : MessageAPI!

  public var delegate : ChatViewControllerDelegate?
  
  public var localAlias : String?
  
  private var lastSentUserStatus = UserStatus.NoStatus
  
  private var recipientsSearchActive = false
  private var recipientsSearchResults : [Contact]?
  
  private var audioPlayer : AVAudioPlayer?
  private var audioRecorder : AVAudioRecorder?
  private var audioUpdateLink : CADisplayLink?
  
  private var currentlyEditingMessage : Message?
  
  private var keyboardRect = CGRect.zero
  
  private var hasAppeared = false
  
  private let operationQueue = OperationQueue()
  
  private var notificationHandlers = [AnyObject]()
  
  @IBOutlet public override var inputView : UIView? {
    get { return _inputView }
    set { _inputView = newValue }
  }
  private var _inputView : UIView?
  
  @IBOutlet public override var inputAccessoryView : UIView? {
    get { return _inputAccessoryView }
    set { _inputAccessoryView = newValue }
  }
  private var _inputAccessoryView : UIView?
  
  @IBOutlet private var toolbar : ChatToolBarView!
  
  @IBOutlet private var recipientsBar : TURecipientsBar!
  @IBOutlet private var recipientsDisplayController : TURecipientsDisplayController!
  
  private var messagesViewController : MessagesViewController!
  
  //FIXME:  private var chatInfoViewController : RTChatInfoDropDownViewController!
  @IBOutlet private var chatInfoContainerView : UIView!
  
  @IBOutlet private var chatInfoButtonItem : UIBarButtonItem!
  
  // MARK: Initialization
  
  deinit {
    DDLogDebug("\(self.dynamicType) dealloc");

    cleanupAudioPlayer()
    cleanupAudioRecorder()
    
    let notCenter = NSNotificationCenter.defaultCenter()
    notificationHandlers.forEach { notCenter.removeObserver($0) }
  }
  
  // MARK: First Responder
  
  public override func canBecomeFirstResponder() -> Bool {
    return presentedViewController == nil
  }
  
  // MARK: View Transitions
  
  public override func viewDidLoad() {
    
    super.viewDidLoad()
    
    // Toolbar init
    //
    
    toolbar = ChatToolBarView(frame: CGRectZero)
    toolbar.delegate = self
    toolbar.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    inputAccessoryView = toolbar
    
    // Recipients Controller & Bar init
    //
    
    recipientsDisplayController.searchResultsTableView
      .registerNib(UINib(nibName: "ContactSearchCell", bundle: NSBundle.muik_frameworkBundle()),
                   forCellReuseIdentifier: SearchCellIdentifier)
    recipientsDisplayController.searchResultsTableView.estimatedRowHeight = 50
    
    // MesasgesViewController init & embed
    //
    
    messagesViewController = MessagesViewController(collectionViewLayout: MessagesViewLayout())
    messagesViewController.willMoveToParentViewController(self)
    
    messagesViewController.view.backgroundColor = UIColor.clearColor()
    messagesViewController.collectionView?.backgroundColor = UIColor.clearColor()

    view.insertSubview(messagesViewController.view, atIndex: 0)
    messagesViewController.view.frame = view.frame
    messagesViewController.view.snp_makeConstraints { make in
      make.edges.equalTo(view)
    }
    
    messagesViewController.didMoveToParentViewController(self)
    
    updateMessagesViewScrolled(false, animated: false)
    
    // Setup UI
    
    if chat != nil {
      
      becomeFirstResponder()
      
      recipientsBar.hidden = true
      
      //FIXME: navigationItem.rightBarButtonItem = chatInfoButtonItem
      
      updateMessagesViewScrolled(false, animated: false)
      
    }
    else {
      
      recipientsBar.becomeFirstResponder()

      recipientsBar.hidden = false
      
      navigationItem.rightBarButtonItem = nil
    }
    
    // Subscribe to notifications
    //
    
    let notCenter = NSNotificationCenter.defaultCenter()
    
    
    // Keyboard updates
    let shower = notCenter.addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: nil) {[weak self] not in
      
      self?.keyboardRect = not.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue ?? CGRect.zero
      
      self?.updateMessagesViewScrolled(true, animated: true)
      
    }
    notificationHandlers.append(shower)
    
    let hider = notCenter.addObserverForName(UIKeyboardDidHideNotification, object: nil, queue: nil) {[weak self] not in
      
      self?.becomeFirstResponder()
    }
    notificationHandlers.append(hider)

    
    // Status bar updates
    let statusBarFrameChange = notCenter.addObserverForName(UIApplicationWillChangeStatusBarFrameNotification, object: nil, queue: nil) {[weak self] not in
      
      if let newFrame = (not.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue)?.CGRectValue() {
      
        self?.updateMessagesViewWithStatusBarFrame(newFrame, scrolled: true, animated: true)
      
      }
      
    }
    notificationHandlers.append(statusBarFrameChange)
    
  }
  
  public override func viewDidLayoutSubviews() {

    super.viewDidLayoutSubviews()
    
    if !hasAppeared {
      messagesViewController.scrollToLatestItemAnimated(false)
    }
    
  }
  
  public override func viewWillAppear(animated: Bool) {
    
    super.viewWillAppear(animated)
    
    // Initialize audio link
    audioUpdateLink = CADisplayLink(target: self, selector: Selector("updateAudioProgress:"))
    audioUpdateLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    audioUpdateLink!.paused = true
    
    if let chat = chat {
      messageAPI.activateChat(chat)
    }
    
    loadDraft()
    
    updateMessagesViewScrolled(false, animated: false)
    updateToolbar()
  }
  
  public override func viewDidAppear(animated: Bool) {
    
    super.viewDidAppear(animated)
    
    hasAppeared = true
    
    if chat == nil {
      recipientsBar.becomeFirstResponder()
    }
    else {
      becomeFirstResponder()
    }
  }
  
  public override func viewWillDisappear(animated: Bool) {
    
    super.viewWillDisappear(animated)
    
    if isMovingFromParentViewController() {
      
      saveDraft()
      
      clearUserStatus()
      
      recipientsBar.text = nil
      
    }
    
    
    recipientsBar.resignFirstResponder()
    resignFirstResponder()
    
    stopAudioRecording()
    stopAudioPlayback()
    
    audioUpdateLink?.invalidate()
    audioUpdateLink = nil
    
    super.viewWillDisappear(animated)
  }
  
  // MARK: UI Updates

  //FIXME: chat info view controller
//  @IBAction func toggleChatInfo(sender: AnyObject?) {
//    
//    if chatInfoContainerView.hidden {
//      
//      chatInfoContainerView.hidden = false
//      chatInfoViewController.view.transform = CGAffineTransformMakeTranslation(0.0, -chatInfoViewController.view.frame.size.height)
//      
//      UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 3, options: [.CurveEaseInOut],
//        animations: {
//          
//          self.chatInfoViewController.view.transform = CGAffineTransformIdentity
//          self.chatInfoButtonItem.customView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
//          
//        },
//        completion: nil)
//      
//    }
//    else {
//
//      UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 3, options: [.CurveEaseInOut],
//        animations: {
//          
//          self.chatInfoViewController.view.transform = CGAffineTransformMakeTranslation(0, -self.chatInfoViewController.view.frame.size.height)
//          self.chatInfoButtonItem.customView?.transform = CGAffineTransformIdentity
//          
//        },
//        completion: { finished in
//          
//          self.chatInfoContainerView.hidden = true
//          
//      })
//
//    }
//    
//  }
  
  func updateMessages() {
    
    guard let chat = self.chat else {
      return
    }
    
    let results = messageAPI.fetchMessagesMatchingPredicate(NSPredicate(format: "chat = %@", chat),
                                                            offset: 0,
                                                            limit: 0,
                                                            sortedBy: [NSSortDescriptor(key: "sent", ascending: true)])
    messagesViewController.messageResultsController = results
    
    try! results.execute()
  }
  
  func updateChat() {
    
    //FIXME: chatInfoViewController.chat = chat

    updateMessages()
    
    updateNavigationItem()
    
    updateRecipientsBar()
    
    updateMessagesViewScrolled(false, animated: isViewLoaded())

    updateToolbar()
    
  }
  
  func updateNavigationItem() {
    
    navigationItem.title = "fix title" //FIXME: chat?.familiarTitle
    //FIXME: navigationItem.rightBarButtonItem = chat != nil ? chatInfoButtonItem : nil
  }
  
  func updateRecipientsBar() {
    
    recipientsBar.hidden = chat != nil
  }
  
  func updateMessagesViewScrolled(scrolled: Bool, animated: Bool) {
    
    let statusBarFrame = UIApplication.sharedApplication().statusBarFrame

    updateMessagesViewWithStatusBarFrame(statusBarFrame, scrolled: scrolled, animated: false)
  }
  
  func updateMessagesViewWithStatusBarFrame(statusBarFrame: CGRect, scrolled: Bool, animated: Bool) {
    
    let topInset = topLayoutGuide.length + insetPadding + CGFloat(recipientsBar.hidden ? 0 : recipientsBar.frame.size.height)
    let bottomInset = insetPadding + keyboardRect.height
    
    messagesViewController.updateInsets(UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0))
    
    if scrolled {
      messagesViewController.scrollToLatestItemAnimated(animated)
    }
    
  }
  
  func updateToolbar() {
    
    toolbar.enabled = chat != nil || !recipientsBar.recipients.isEmpty
  }
  
  // MARK: User Status
  
  func sendUserStatus(status: UserStatus) {
    
    if let userChat = chat as? UserChat {
      messageAPI.sendUserStatus(status, withSender: userChat.localAlias, toRecipient: userChat.alias)
    }
    else if let groupChat = chat as? GroupChat {
      messageAPI.sendUserStatus(status, withSender: groupChat.localAlias, toMembers: groupChat.activeRecipients, inChat: groupChat.id)
    }
    
    lastSentUserStatus = status
  }
  
  func clearUserStatus() {
    
    if lastSentUserStatus != .NoStatus {
      sendUserStatus(.NoStatus)
    }
    
  }
  
  // MARK: Drafts
  
  func loadDraft() {
    
    if let chat = chat, draft = chat.draft as? String {
      
      toolbar.currentMessages = [draft]
      
      chat.draft = nil
    
      try! messageAPI.updateChatLocally(chat)
      
    }
    
  }
  
  func saveDraft() {
    
    guard let chat = chat where currentlyEditingMessage == nil && toolbar.hasCurrentMessages else {
      return
    }
    
    var draft = ""
    
    for message in toolbar.currentMessages {
        
      switch message {
      case let text as String:
        draft += text
          
      default:
        return
      }
        
    }
      
    chat.draft = draft
      
    try! messageAPI.updateChatLocally(chat)
  }
  
  // MARK: Messages
  
  private func saveMessageWithData(data: MessageData) {
    
    let save = SaveOperation(data: data, previousMessage: currentlyEditingMessage, vc: self)
    operationQueue.addOperation(save)
    
    endCurrentMessageEditing()
    
    lastSentUserStatus = .NoStatus
  }
  
  // MARK: Message Editing
  
  func beginMessageEditingAtIndexPath(indexPath: NSIndexPath) {
    
    cancelCurrentMessageEditing()
    
    // TODO: currentlyEditingMessage = messagesViewController.messageAtIndexPath(indexPath)
    
    switch currentlyEditingMessage {
      
    case let message as TextMessage:
      
      toolbar.hideToolBarButtons()
      toolbar.currentMessages = [message.text]
      
      // TODO: messagesViewController.showEditorForMessageAtIndexPath(indexPath)
      
      sendUserStatus(.Typing)
      
    case is ImageMessage:
      
      pickImage()
      
      sendUserStatus(.Photographing)
      
      
    case is VideoMessage:
      
      pickVideo()
      
      sendUserStatus(.RecordingVideo)
      
    case is AudioMessage:
      
      toolbar.showAudioPlaybackControls()
      toolbar.updateAudioPlaybackMode(.New)
      
      // TODO: messagesViewController.showEditorForMessageAtIndexPath(indexPath)
      
      sendUserStatus(.RecordingAudio)
      
    case is ContactMessage:
      
      pickContact()
      
      sendUserStatus(.SelectingContact)
      
    case is LocationMessage:
      
      pickLocation()
      
      sendUserStatus(.Locating)
      
    default:
      
      currentlyEditingMessage = nil
      
      // TODO: messagesViewController.hideMenuForItemAtIndexPath(indexPath, animated: true)
    }
    
  }
  
  func endCurrentMessageEditing() {
    
    // TODO: messagesViewController.hideCurrentEditorForMessage()
  }
  
  func cancelCurrentMessageEditing() {
    
    endCurrentMessageEditing()
    
    if currentlyEditingMessage is AudioMessage {
      
      cleanupAudioRecorder()
      
      toolbar.hideWaveformView()
      toolbar.hideAudioPlaybackControls()
    }
    
    currentlyEditingMessage = nil
  }
  
  // MARK: Picking UI
  
  func pickImage() {
    //FIXME: operationQueue.addOperation(PickMedia(vc: self, type: .Photo))
  }
  
  func pickVideo() {
    //FIXME: operationQueue.addOperation(PickMedia(vc: self, type: .Video))
  }
  
  func pickContact() {
    //FIXME: operationQueue.addOperation(PickContact(vc: self))
  }
  
  func pickLocation() {
    //FIXME: operationQueue.addOperation(PickLocation(vc: self));
  }
  
}

// MARK: Toolbar Delegate
extension ChatViewController : ChatToolBarViewDelegate {
  
  public func chatToolBarViewDidTapSend(chatToolBarView: ChatToolBarView) {
    
    for message in chatToolBarView.currentMessages {

      let data : MessageData
      
      switch message {
      case let image as UIImage:
        data = .Image(nil, image, nil)
        
      default:
        data = .Text(message.description)
      }
      
      let save = SaveOperation(data: data, previousMessage: currentlyEditingMessage, vc: self)
      operationQueue.addOperation(save)
    }
    
  }
  
  public func chatToolBarViewWillShowButtons(chatToolBarView: ChatToolBarView) {
    
    cancelCurrentMessageEditing()
  }
  
  public func chatToolBarViewDidStartTyping(chatToolBarView: ChatToolBarView) {
    
    sendUserStatus(.Typing)
  }
  
  public func chatToolBarViewDidEndTyping(chatToolBarView: ChatToolBarView) {

    sendUserStatus(.NoStatus)
  }
  
  public func chatToolBarViewDidTapCamera(chatToolBarView: ChatToolBarView) {
    
    pickImage()
    
    sendUserStatus(.Photographing)
  }
  
  public func chatToolBarViewBeganPressingCamera(chatToolBarView: ChatToolBarView) {
    
    let cameraController = UIImagePickerController()
    cameraController.sourceType = .Camera
    cameraController.mediaTypes = [kUTTypeImage as String]
    
    promiseViewController(cameraController).then { (info: [String: AnyObject]) -> Void in
      
      let assetURL = info[UIImagePickerControllerReferenceURL] as? NSURL
      let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage
      let metaData = info[UIImagePickerControllerMediaMetadata] as? [String: AnyObject]
      
      self.saveMessageWithData(.Image(assetURL, image, metaData))
      
    }

    sendUserStatus(.Photographing)
  }
  
  public func chatToolBarViewBeganPressingAudio(chatToolBarView: ChatToolBarView) {
    
    requestAudioRecordingWithCompletion { started in
      
      if started {
        
        self.toolbar.showWaveformView()
        
        self.sendUserStatus(.RecordingAudio)
        
      }
      
    }
    
  }
  
  public func chatToolBarViewEndedPressingAudio(chatToolBarView: ChatToolBarView, flicked: Bool) {
    
    toolbar.hideWaveformView()

    stopAudioRecording()
    
    if flicked {
      
      sendCurrentAudio()

    }
    else {
      
      toolbar.showAudioPlaybackControls()
      
      loadCurrentAudioPlaybackData()
      
    }
    
  }
  
  public func chatToolBarViewCanceledPressingAudio(chatToolBarView: ChatToolBarView) {
    
    cleanupAudioRecorder()
    
    toolbar.hideWaveformView()
    toolbar.hideAudioPlaybackControls()
    
    cancelCurrentMessageEditing()
    
    sendUserStatus(.NoStatus)
    
  }
  
  public func chatToolBarViewDidTapAudioPlaybackPlay(chatToolBarView: ChatToolBarView) {
    
    startAudioPlayback()
    
    toolbar.updateAudioPlaybackMode(.Playing)
  }
  
  public func chatToolBarViewDidTapAudioPlaybackPause(chatToolBarView: ChatToolBarView) {
    
    pauseAudioPlayback()
    
    toolbar.updateAudioPlaybackMode(.Paused)
  }
  
  public func chatToolBarViewDidTapAudioPlaybackCancel(chatToolBarView: ChatToolBarView) {
    
    cleanupAudioRecorder()
    
    toolbar.hideWaveformView()
    toolbar.hideAudioPlaybackControls()
    
    cancelCurrentMessageEditing()
    
    sendUserStatus(.NoStatus)
  }
  
  public func chatToolBarViewDidTapAudioPlaybackReset(chatToolBarView: ChatToolBarView) {
    
    stopAudioRecording()
    
    toolbar.hideWaveformView()
    toolbar.updateAudioPlaybackMode(.New)
  }
  
  public func chatToolBarViewDidTapAudioPlaybackRecord(chatToolBarView: ChatToolBarView) {
    
    requestAudioRecordingWithCompletion { started in
      
      if started {
        
        self.toolbar.showWaveformView()
        self.toolbar.updateAudioPlaybackMode(.Recording)
        
      }
      
    }
    
  }
  
  public func chatToolBarViewDidTapAudioPlaybackStop(chatToolBarView: ChatToolBarView) {
    
    stopAudioRecording()

    toolbar.hideWaveformView()

    loadCurrentAudioPlaybackData()
  }
  
  public func chatToolBarViewDidTapAudioPlaybackSend(chatToolBarView: ChatToolBarView) {
    
    stopAudioRecording()
    
    toolbar.hideWaveformView()
    toolbar.hideAudioPlaybackControls()
    
    if audioRecorder != nil {
      
      sendCurrentAudio()
      
    }
    else {
      
      sendUserStatus(.NoStatus)

      cancelCurrentMessageEditing()

    }
    
  }
  
  public func chatToolBarViewDidTapAudio(chatToolBarView: ChatToolBarView) {
    
    toolbar.showAudioPlaybackControls()
    toolbar.updateAudioPlaybackMode(.New)
    
    sendUserStatus(.RecordingAudio)
  }
  
  public func chatToolBarViewDidTapVideo(chatToolBarView: ChatToolBarView) {

    pickVideo()

    sendUserStatus(.RecordingVideo)
  }
  
  public func chatToolBarViewBeganPressingVideo(chatToolBarView: ChatToolBarView) {

    let cameraController = UIImagePickerController()
    cameraController.sourceType = .Camera
    cameraController.mediaTypes = [kUTTypeMovie as String]
    promiseViewController(cameraController).then { (info: [String: AnyObject]) -> Void in

      if let assetURL = info[UIImagePickerControllerReferenceURL] as? NSURL ?? info[UIImagePickerControllerMediaURL] as? NSURL {
        
        self.saveMessageWithData(.Video(assetURL))
        
      }
      else {
        
        DDLogError("No URL to source video")
        
      }
      
    }
    
    presentViewController(cameraController, animated: true, completion: nil)

    sendUserStatus(.RecordingVideo)
  }
 
  public func chatToolBarViewDidTapContact(chatToolBarView: ChatToolBarView) {
    
    pickContact()
    
    sendUserStatus(.SelectingContact)
  }
  
  public func chatToolBarViewDidTapLocation(chatToolBarView: ChatToolBarView) {
    
    pickLocation()
    
    sendUserStatus(.Locating)
  }
  
}



// MARK: Audio Player/Recorder Delegates
extension ChatViewController : AVAudioPlayerDelegate, AVAudioRecorderDelegate {

  // MARK: Audio Recording
  
  func requestAudioRecordingWithCompletion(completion: (started: Bool) -> Void) {
    
    stopAudioPlayback()
    
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      
      if !granted {
        
        GCD.mainQueue.async {
          
          completion(started: false)
          
          let alert = UIAlertController(title: "Microphone Access",
                                        message: "You currently have access to your microphone disabled. You need to open Settings and enable microphone access before you can send audio messages.",
                                        preferredStyle: .Alert)
          
          alert.addAction(UIAlertAction(title: "Ok", style: .Cancel) { action in
            
            // Do nothing
            
          })
          
          alert.addAction(UIAlertAction(title: "Settings", style: .Default) { action in
            
            // Open Settings
            
            if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
              UIApplication.sharedApplication().openURL(settingsURL)
            }
            
          })
          
        }
        
      }
      else {
        
        let started = self.startAudioRecording()
        
        GCD.mainQueue.async {
          completion(started: started)
        }
        
      }
      
    }
    
  }
  
  func startAudioRecording() -> Bool {
    
    let fileName = "\(Int(NSDate().timeIntervalSince1970)).m4a"
    let tempFileURL = NSURL.fileURLWithPath(NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)

    let settings = [
      AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
      AVSampleRateKey: NSNumber(float: 16000.0),
      AVNumberOfChannelsKey: NSNumber(int: 1)
    ]
    
    do {
      
      audioRecorder = try AVAudioRecorder(URL: tempFileURL, settings: settings)
      
    }
    catch let error as NSError {
      
      DDLogError("Error creating audio recorder: \(error.description)")
      
      return false
    }

    guard let audioRecorder = audioRecorder else {
      return false
    }
    
    audioRecorder.delegate = self
    audioRecorder.meteringEnabled = true
    
    if (!audioRecorder.record()) {
      DDLogError("Unable to start recording")
      audioRecorder.deleteRecording()
      self.audioRecorder = nil
      return false
    }
    
    audioUpdateLink?.paused = false
    
    return true
  }
  
  func stopAudioRecording() {
    
    if let audioRecorder = audioRecorder {
      
      if audioRecorder.recording {
        
        DDLogDebug("Stop audio recording")
        
        audioRecorder.stop()
        
      }
      
      audioUpdateLink?.paused = true
    }
  }
  
  func cleanupAudioRecorder() {
    
    stopAudioRecording()
    
    audioRecorder?.deleteRecording()
    
    audioRecorder = nil
  }
  
  // MARK: Audio Playback
  
  func startAudioPlayback() {
    
    if let mediaURL = audioRecorder?.url where audioPlayer == nil {
      
      audioPlayer = try? AVAudioPlayer(contentsOfURL: mediaURL)
      
      audioPlayer!.delegate = self
    }

    resumeAudioPlayback()
  }

  func pauseAudioPlayback() {
    
    audioPlayer?.pause()
    audioUpdateLink?.paused = true
  }
  
  func resumeAudioPlayback() {
    
    audioPlayer?.play()
    audioUpdateLink?.paused = false
  }
  
  func stopAudioPlayback() {
    
    if let audioPlayer = audioPlayer {
      
      if audioPlayer.playing {
        audioPlayer.stop()
      }
      
    }
    
    audioPlayer = nil
    audioUpdateLink?.paused = true
  }
  
  func cleanupAudioPlayer() {
    
    stopAudioPlayback()
  }
  
  func sendCurrentAudio() {
    
    if let audioRecorder = audioRecorder {
      
      saveMessageWithData(.Audio(audioRecorder.url))

      self.audioRecorder = nil

    }
    else {
      DDLogError("No audio to send")
    }
    
  }
  
  func loadCurrentAudioPlaybackData() {
    
    if let audioRecorder = audioRecorder {
      
      
      toolbar.updateAudioPlaybackMode(.Stopped)
      
      if let file = AudioFile(URL: audioRecorder.url) {
        
        file.generateSampleData(32, completion: {
          
          GCD.mainQueue.async {
            self.toolbar.updateAudioPlaybackDataWithTime(file.duration, samples: file.samples, count: file.sampleCount)
          }
          
        },
        error: { error in
        })
      }
      
      
    }
  }

}

private let OpenSettingsCellIdentifier = "Settings"
private let SearchCellIdentifier = "Search"

// MARK: Recipient Display Delegate
extension ChatViewController : TURecipientsDisplayDelegate, UITableViewDataSource, UITableViewDelegate {
  
  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    if !ContactsManager.sharedProvider.accessGranted {
      return 1
    }
    
    return recipientsSearchResults?.count ?? 0
  }
  
  public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let cell : UITableViewCell
    
    if let results = recipientsSearchResults {

      let searchCell =
        tableView.dequeueReusableCellWithIdentifier(SearchCellIdentifier) as? ContactSearchCell ??
        ContactSearchCell(style: .Subtitle, reuseIdentifier: SearchCellIdentifier)
      
      let contact = results[indexPath.row]
      
      searchCell.titleLabel.text = contact.fullName

      if #available(iOS 9.0, *) {
        
        let aliasesStackView = searchCell.aliasesStackView as! UIStackView
        aliasesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for kind in [ContactAliasKind.Phone, ContactAliasKind.Email, ContactAliasKind.InstantMessage, ContactAliasKind.Other] {
          
          let aliases = contact.aliases.filter { $0.kind == kind }
          if !aliases.isEmpty {
            
            let kindLabel = UILabel()
            kindLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2).bold()
            
            switch kind {
            case .Phone:
              kindLabel.text = "Phones"
            case .Email:
              kindLabel.text = "Emails"
            case .InstantMessage:
              kindLabel.text = "IMs"
            case .Other:
              kindLabel.text = "Others"
            }
            
            aliasesStackView.addArrangedSubview(kindLabel)
            
            for alias in aliases {
              let aliasLabel = UILabel()
              aliasLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
              aliasLabel.text = " \(alias.label ?? "General"): \(alias.value)"
              aliasesStackView.addArrangedSubview(aliasLabel)
            }
            
          }
          
        }
        
      }
      
      cell = searchCell
    }
    else if !ContactsManager.sharedProvider.accessGranted {
      
      cell = tableView.dequeueReusableCellWithIdentifier(OpenSettingsCellIdentifier) ??
        UITableViewCell(style: .Subtitle, reuseIdentifier: OpenSettingsCellIdentifier)
      
      cell.textLabel!.text = "Enable contacts to see them here..."
      cell.textLabel!.textColor = UIColor.lightGrayColor()
      cell.detailTextLabel!.text = "Tap here to open Settings and enable them"
      cell.detailTextLabel!.textColor = UIColor.lightGrayColor()

    }
    else {
      fatalError("Invalid cell request")
    }
    
    cell.layoutIfNeeded()
    
    return cell
  }
  
  public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
      return
    }
    
    // Did they click the suggestion to enable contacts access in settings?
    if cell.reuseIdentifier == OpenSettingsCellIdentifier {
      UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
      return
    }

    guard let results = recipientsSearchResults else {
      return
    }
    
    let contact = results[indexPath.row]
    
    guard let recipient = delegate?.chatViewController?(self, wantsRecipientForContact: contact) else {
      return
    }
    
    recipientsBar.addRecipient(recipient)
    recipientsDisplayController(recipientsDisplayController, didAddRecipient: recipient)
    
    recipientsBar.text = nil

    updateToolbar()
  }
  
  public func recipientsBarAddButtonClicked(recipientsBar: TURecipientsBar!) {
    
    recipientsBar.text = nil
    
    guard let pickOp = delegate?.chatViewControllerRequestedPickContactOperation?(self) else {
      return
    }
    
    pickOp.addObserver(BlockObserver(finishHandler: { op, error in
      
      guard let contact = pickOp.contact else {
        return
      }
      
      guard let recipient = self.delegate?.chatViewController?(self, wantsRecipientForContact: contact) else {
        return
      }
      
      recipientsBar.addRecipient(recipient)
      self.recipientsDisplayController(self.recipientsDisplayController, didAddRecipient: recipient)
      
      self.updateToolbar()
    }))
    
    operationQueue.addOperation(pickOp)
  }
  
  public func recipientsDisplayController(controller: TURecipientsDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
    
    if !recipientsSearchActive {
      
      recipientsSearchActive = true
      
      GCD.userInitiatedQueue.async {
        
        let foundContacts = ContactsManager.sharedProvider.searchWithQuery(searchString)
        
        // Generate set of all aliases in use by the currently selected recipients
        let recipientAliases =
          Set(self.recipientsBar.recipients.flatMap { ($0 as? ChatRecipient)?.alias })
        
        // Exclude contacts that have already been added by matching up aliases
        let resultsContacts = foundContacts.filter { Set($0.aliases.map { $0.value }).intersect(recipientAliases).isEmpty }
        
        self.recipientsSearchResults = resultsContacts.isEmpty ? nil : resultsContacts
        
        self.recipientsSearchActive = false
        
        GCD.mainQueue.async {
          self.recipientsDisplayController.searchResultsTableView.reloadData()
        }

      }
    }
    
    return false
  }
  
  public func recipientsDisplayController(controller: TURecipientsDisplayController!, willAddRecipient recipient: TURecipientProtocol!) -> TURecipientProtocol! {
    
    // Only need to process if this isn't a recipient of our making
    if recipient is ChatRecipient {
      return recipient
    }
    
    let proposedAlias = recipient.recipientTitle!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    if proposedAlias.isEmpty {
      return nil
    }
    
    guard let recipient = delegate?.chatViewController?(self, wantsRecipientForProposedAlias: proposedAlias) else {
      return nil
    }
    
    // If a recipient already includes this alias, don't add anything
    if recipientsBar.recipients.flatMap({$0 as? ChatRecipient}).contains({ $0.alias == recipient.alias }) {
      recipientsBar.text = nil
      return nil
    }
    
    return recipient
  }
  
  public func recipientsDisplayController(controller: TURecipientsDisplayController!, didAddRecipient recipient: TURecipientProtocol!) {
    
    guard let recipient = recipient as? ChatRecipient else {
      DDLogWarn("Recipient is not a ChatRecipient (and it should be!")
      return
    }
    
    operationQueue.addOperation(ValidateRecipientOperation(recipient: recipient, vc: self))
  }
  
  public func recipientsDisplayController(controller: TURecipientsDisplayController!, didRemoveRecipient recipient: TURecipientProtocol!) {
    
    updateToolbar()
    
    // If no modal view is presented have
    // recipients bar become first responder
    if presentedViewController == nil {
      recipientsBar.becomeFirstResponder()
    }
    
  }
  
}


// MARK: Messages View Controller Delegate
//extension ChatViewController : MessagesViewControllerDelegate {
//  
//  func messageActionRequestedAtIndexPath(indexPath: NSIndexPath!) {
//
//    if let message = messagesViewController.messageAtIndexPath(indexPath) where !message.sentByMe {
//      
//      messageAPI.clarifyMessage(message)
//      
//    }
//    
//  }
//  
//  func messageEditRequestedAtIndexPath(indexPath: NSIndexPath!) {
//    
//    if let message = messagesViewController.messageAtIndexPath(indexPath) where message.sentByMe {
//      
//      beginMessageEditingAtIndexPath(indexPath)
//      
//    }
//    
//  }
//  
//  func messageDeleteRequestedAtIndexPath(indexPath: NSIndexPath!) {
//    
//    if let message = messagesViewController.messageAtIndexPath(indexPath) {
//      
//      messageAPI.deleteMessage(message)
//      
//    }
//    
//  }
//  
//  func messageEditingEndedAtIndexPath(indexPath: NSIndexPath!) {
//    
//    toolbar.currentMessages = nil
//    
//  }
//  
//  func messageEditingCanceledAtIndexPath(indexPath: NSIndexPath!) {
//    
//    cancelCurrentMessageEditing()
//    
//    messageEditingEndedAtIndexPath(indexPath)
//    
//    sendUserStatus(.NoStatus)
//  }
//  
//}

// MARK: Operations & Conditions

//private class PickMedia : Operation, RTImagePickerControllerDelegate {
//  
//  
//  let vc : ChatViewController
//  
//  let type : RTImagePickerControllerType
//  
//  
//  init(vc: ChatViewController, type: RTImagePickerControllerType) {
//    self.vc = vc
//    self.type = type
//    
//    super.init()
//    
//    addCondition(ModalCondition())
//  }
//  
//  override func execute() {
//    
//    let pickerNav = UIStoryboard(name: "RTImagePickerController", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as! UINavigationController
//    let picker = pickerNav.topViewController as! RTImagePickerController
//    picker.delegate = self
//    picker.type = type
//    
//    GCD.mainQueue.async {
//      self.vc.presentViewController(pickerNav, animated: true, completion: nil)
//    }
//  }
//  
//  @objc func imagePickerController(picker: RTImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
//    
//    let assetURL = info[UIImagePickerControllerReferenceURL] as? NSURL
//    let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage
//    let metaData = info[UIImagePickerControllerMediaMetadata] as? [String: AnyObject]
//    
//    vc.saveMessageWithData(.Image(assetURL, image, metaData))
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//  }
//  
//  @objc func imagePickerControllerDidCancel(picker: RTImagePickerController!) {
//
//    vc.cancelCurrentMessageEditing()
//    vc.sendUserStatus(.NoStatus)
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//  }
//  
//}
//
//private class PickLocation : Operation, RTLocationViewControllerDelegate {
//  
//  
//  let vc : ChatViewController
//  
//  
//  init(vc: ChatViewController) {
//    self.vc = vc
//
//    super.init()
//    
//    addCondition(ModalCondition())
//  }
//  
//  override func execute() {
//    
//    let locationVC = RTLocationViewController.locationControllerWithType(.Picker)
//    locationVC.type = .Picker
//    
//    let locationNavVC = UINavigationController(rootViewController: locationVC)
//    
//    GCD.mainQueue.async {
//      self.vc.presentViewController(locationNavVC, animated: true, completion: nil)
//    }
//  }
//  
//  @objc func locationViewController(picker: RTLocationViewController!, didFinishPickingLocation location: CLLocation!) {
//
//    vc.saveMessageWithData(.Location(location))
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//  }
//  
//  @objc func locationViewControllerDidCancel(picker: RTLocationViewController!) {
//    
//    vc.cancelCurrentMessageEditing()
//    vc.sendUserStatus(.NoStatus)
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//  }
//  
//}
//
//private class PickContact : Operation, ABPeoplePickerNavigationControllerDelegate {
//  
//  let vc : ChatViewController
//  
//  init(vc: ChatViewController) {
//
//    self.vc = vc
//    
//    super.init()
//    
//    addCondition(ModalCondition())
//  }
//  
//  override func execute() {
//
//    let peoplePickerVC = ABPeoplePickerNavigationController()
//    peoplePickerVC.peoplePickerDelegate = self
//    peoplePickerVC.predicateForSelectionOfPerson = NSPredicate(value: true)
//    
//    GCD.mainQueue.async {
//      self.vc.presentViewController(peoplePickerVC, animated: true, completion: nil)
//    }
//  }
//  
//  @objc func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
//    
//    vc.saveMessageWithData(.Contact(person))
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//    
//  }
//  
//  @objc func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController) {
//
//    vc.cancelCurrentMessageEditing()
//    vc.sendUserStatus(.NoStatus)
//    
//    vc.dismissViewControllerAnimated(true) {
//      self.finish()
//    }
//    
//  }
//  
//}


private class SaveOperation : Operation {
  
  enum ErrorCode: ErrorType {
    case InvalidImageReference
    case InvalidImageType
  }

  
  let data : MessageData
  
  let previousMessage : Message?
  
  let vc : ChatViewController
  
  
  init(data: MessageData, previousMessage: Message?, vc: ChatViewController) {
    
    self.data = data
    self.previousMessage = previousMessage
    self.vc = vc
    
    super.init()
    
    addCondition(ChatResolvedCondition(vc: vc))       // Ensure a chat is loaded
    addCondition(MutuallyExclusive<SaveOperation>())  // Ensure saves happen in order
  }
  
  override func execute() {
    
    switch data {
    case .Text(let value):
      
      let (textMessage, update) = instanceToSaveOfClass(TextMessage.self, previousMessage: previousMessage)

      textMessage.text = value
      
      saveMessage(textMessage, update: update)
      
      finish()
      
    case .Image(let assetURL, let image, let metaData):
      
      let (imageMessage, update) = instanceToSaveOfClass(ImageMessage.self, previousMessage: previousMessage)

      exportImage(assetURL, metaData: metaData) { (dataFileURL, error) in
        
        if dataFileURL == nil  {
          
          guard let image = image else {
            self.finishWithError(ErrorCode.InvalidImageReference as NSError)
            return
          }

          var type : NSString?
          let data = image.exportOptimizedWithMetadata(metaData, type: &type)
          
          guard let imageType = type, fileExt = UTTypeCopyPreferredTagWithClass(imageType as CFString, kUTTagClassFilenameExtension) else {
            self.finishWithError(ErrorCode.InvalidImageType as NSError)
            return
          }
          
          
          //FIXME: dataFileURL = ImageMessage.generateDataURLWithExtension(fileExt.takeRetainedValue() as String)
          
          do {
            try data.writeToURL(dataFileURL!, options: [])
          }
          catch let error as NSError {
            self.finishWithError(error)
            return
          }
          
        }
        
        //FIXME: imageMessage.thumbnailData = ImageMessage.generateThumbnailData(RTDataRef(URL: dataFileURL!), size: &imageMessage.thumbnailSize)
        //FIXME: imageMessage.dataURL = dataFileURL
        
        self.saveMessage(imageMessage, update: update)
        
        self.finish()
      }
      
      
    case .Audio(let assetURL):
      
      let (audioMessage, update) = instanceToSaveOfClass(AudioMessage.self, previousMessage: previousMessage)
      
      let dataFileURL = NSURL() //FIXME: AudioMessage.generateDataURLWithExtension(assetURL.pathExtension!)
      
      do {
        try NSFileManager.defaultManager().moveItemAtURL(assetURL, toURL: dataFileURL)
      }
      catch let error as NSError {
        self.finishWithError(error)
      }
      
      //FIXME: audioMessage.dataURL = dataFileURL
      
      saveMessage(audioMessage, update: update)
      
      finish()
      
      
    case .Video(let assetURL):
      
      let (videoMessage, update) = instanceToSaveOfClass(VideoMessage.self, previousMessage: previousMessage)

      do {
        
        let dataFileURL = NSURL() //FIXME: VideoMessage.generateDataURLWithExtension(assetURL.pathExtension!)
        try NSFileManager.defaultManager().copyItemAtURL(assetURL, toURL: dataFileURL)
      
        //FIXME: videoMessage.thumbnailData = VideoMessage.generateThumbnailData(dataFileURL, atFrameTime: "00:00:00:0000", size: &videoMessage.thumbnailSize)
        //FIXME: videoMessage.dataURL = dataFileURL
        
        saveMessage(videoMessage, update: update)
        
        finish()
      }
      catch let error as NSError {
        finishWithError(error)
      }
      
    case .Contact(let personRecord):

      let (contactMessage, update) = instanceToSaveOfClass(ContactMessage.self, previousMessage: previousMessage)
      
      contactMessage.vcardData = ABPersonCreateVCardRepresentationWithPeople([personRecord]).takeRetainedValue()
      contactMessage.firstName = ABRecordCopyValue(personRecord, kABPersonFirstNameProperty).takeRetainedValue() as? String
      contactMessage.lastName = ABRecordCopyValue(personRecord, kABPersonLastNameProperty).takeRetainedValue() as? String
      
      saveMessage(contactMessage, update: update)
      
      finish()
      
    case .Location(let location):
      
      let (locationMessage, update) = instanceToSaveOfClass(LocationMessage.self, previousMessage: previousMessage)
      
      locationMessage.longitude = location.coordinate.longitude
      locationMessage.latitude = location.coordinate.latitude
      
      saveMessage(locationMessage, update: update)
      
      finish()

    }
  
  }
  
  func saveMessage(message: Message, update: Bool) {
    if update {
      vc.messageAPI.updateMessage(message)
    }
    else {
      vc.messageAPI.saveMessage(message)
    }
  }
  
  func exportImage(assetURL: NSURL?, metaData: [String: AnyObject]?, handler: (dataFileURL: NSURL?, error: NSError?) -> Void) {
    
    if let assetURL = assetURL {
      
      let assetsLibrary = ALAssetsLibrary()
      
      assetsLibrary.assetForURL(assetURL, resultBlock: { asset in
        
        do {
        
          if asset != nil {
            
            asset
            
            let assetRep = asset.defaultRepresentation()
          
            guard let fileExt = UTTypeCopyPreferredTagWithClass(assetRep.UTI(), kUTTagClassFilenameExtension)?.takeRetainedValue() as? String else {
              //TODO: pass error
              handler(dataFileURL: nil, error: nil)
              return
            }
            
            let dataFileURL = NSURL(forTemporaryFileWithExtension: fileExt)
            
            let dataFileStream = NSOutputStream(URL: dataFileURL, append: false)!
            dataFileStream.open()
            if let error = dataFileStream.streamError {
              throw error
            }
            
            defer {
              dataFileStream.close()
            }
            
            let data = NSMutableData(length: 256*1024)!
            let dataBytes = UnsafeMutablePointer<UInt8>(data.mutableBytes)
            
            var totalDataRead = Int64(0)
            
            repeat {
            
              var error : NSError?
              
              let lastDataRead = assetRep.getBytes(dataBytes, fromOffset: totalDataRead, length: data.length, error: &error)
              if lastDataRead == 0 && error != nil {
                throw error!
              }
              
              if dataFileStream.write(dataBytes, maxLength: lastDataRead) == -1 {
                if let error = dataFileStream.streamError {
                  throw error
                }
              }
            
              totalDataRead += lastDataRead
              
            } while totalDataRead < assetRep.size()
            
            handler(dataFileURL: dataFileURL, error: nil)
          }
          
        }
        catch let error as NSError {
          
          handler(dataFileURL: nil, error: error)
          
        }
        
      },
      failureBlock: { error in
        
        handler(dataFileURL: nil, error: error)
        
      })
      
    }
    
  }
  
  func instanceToSaveOfClass<T: Message>(messageType: T.Type, previousMessage: AnyObject?) -> (T, Bool) {
    
    if let previousMessage = previousMessage as? T {
      return (previousMessage, true)
    }
    
    let message = messageType.init(chat: vc.chat!)
    return (message, false)
  }

}

private class ChatResolvedCondition : OperationCondition {
  
  static let name = "ChatResolved"
  
  static let isMutuallyExclusive = false
  
  
  let vc : ChatViewController
  
  
  init(vc: ChatViewController) {
    self.vc = vc
  }
  
  func dependencyForOperation(operation: Operation) -> NSOperation? {
    
    // Attempt to resolve it if it doesn't currently exist
    if vc.chat == nil {
      return ResolveChatOperation(vc: vc)
    }
    
    return nil
  }
  
  func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
    return completion(vc.chat != nil ?
      OperationConditionResult.Satisfied :
      OperationConditionResult.Failed(NSError(code: .ConditionFailed, userInfo: [OperationConditionKey: self.dynamicType.name])))
  }
  
}

private class ResolveChatOperation : Operation {
  
  let vc : ChatViewController
  
  init(vc: ChatViewController) {
    
    self.vc = vc
    
    super.init()

    // Add all of this chat's recipient validation
    // operations as dependencies
    addDependencies(vc.operationQueue.operations.filter { op in
      
      guard let op = op as? ValidateRecipientOperation else {
        return false
      }
      
      return op.vc == vc
    })
    
    addCondition(MutuallyExclusive<ResolveChatOperation>())
  }
  
  override func execute() {
    
    defer {
      finish()
    }
    
    if vc.chat != nil {
      return
    }
    
    let recipients = vc.recipientsDisplayController.recipientsBar.recipients as! [ChatRecipient]
    let recipientAliases = recipients.map { $0.alias }
    
    if recipientAliases.isEmpty {
      return
    }
    
    let localAlias = vc.localAlias ?? vc.messageAPI.credentials.allAliases.first!
    
    if recipientAliases.count == 1 {
      vc.chat = try! vc.messageAPI.loadUserChatForAlias(recipientAliases[0], localAlias: localAlias)
    }
    else {
      vc.chat = try! vc.messageAPI.loadGroupChatForId(Id.generate(), members: Set(recipientAliases), localAlias: localAlias)
    }
    
  }
  
}

private class ValidateRecipientOperation : Operation {
  
  let recipient : ChatRecipient
  let vc : ChatViewController
  
  init(recipient: ChatRecipient, vc: ChatViewController) {
    
    self.recipient = recipient
    self.vc = vc
    
    super.init()
    
    addCondition(ReachabilityCondition(host: MessageAPI.target.baseURL))
  }
  
  override func execute() {

    MessageAPI.findUserInfoWithAlias(recipient.alias).then { info -> Void in
      
      if info == nil {
        
        self.vc.recipientsBar.removeRecipient(self.recipient)
        
        let invite = InviteOperation(recipient: self.recipient, vc: self.vc)
        
        self.produceOperation(invite)
      }
      
      self.finish()
    }
    .error { error in
      
      self.finishWithError(error as NSError)
      
      return
    }
    
  }
  
}


private class InviteOperation : Operation {
  
  enum Error : ErrorType {
    case CannotSendSMS
    case CannotSendEmail
    case Failed
  }
  
  let recipient : ChatRecipient
  let vc : ChatViewController
  
  init(recipient: ChatRecipient, vc: ChatViewController) {
    
    self.recipient = recipient
    self.vc = vc
    
    super.init()
    
    addCondition(AlertPresentation())
  }
  
  override func execute() {
    
    let message = "\(self.recipient.recipientTitle) is not a reTXT user yet!"

    GCD.mainQueue.async {
      
      let ask = PMKAlertController(title: "Unknown User", message: message)

      ask.addActionWithTitle("Ok", style: .Cancel)
      ask.addActionWithTitle("Invite", style: .Default)
    
      self.vc.promiseViewController(ask)
      
      self.finish()
      
        //FIXME:
//        .then { action -> Promise<(ChatRecipient, NSNumber?)> in
//      
//          let inviterRecipient = Recipient()
//          inviterRecipient.name = self.recipient.recipientTitle
//
//          inviterRecipient.alias = self.recipient.alias
//          inviterRecipient.aliasType = self.recipient.alias.typeOfAlias()
//          
//          return RTAppDelegate.showViralSheetWithViewController(self.vc, initialRecipient: inviterRecipient).then(on: zalgo) { loaded in
//            return (inviterRecipient, loaded as? NSNumber)
//          }
//          
//          return Promise<(Recipient, NSNumber?)>((Recipient(), nil as NSNumber?))
//      
//        }.then { recipient, loaded -> Promise<Any?> in
//          
//          guard let loaded = loaded where loaded == false else {
//            return Promise(true)
//          }
//          
//        switch recipient.aliasType {
//        case .PhoneNumber:
//          
//          if !MFMessageComposeViewController.canSendText() {
//            return Promise(error: Error.CannotSendSMS)
//          }
//
//          return Promise<Any?>(nil)
//        return self.vc.messageAPI.createInvite(recipient.alias).then { invite -> Promise<Any?> in
//          
//          guard let invite = invite as? RTInvite else {
//            return Promise(error: Error.Failed)
//          }
//          
//          let composer = MFMessageComposeViewController()
//          
//          composer.recipients = [recipient.alias]
//          composer.body = invite.bodyText
//          
//          return self.vc.promiseViewController(composer).then { () -> Any? in
//
//            return true
//          }
//          
//        }
//          
//        case .EMailAddress:
//          
//          if !MFMailComposeViewController.canSendMail() {
//            return Promise(error: Error.CannotSendEmail)
//          }
//
//          return Promise<Any?>(nil)
//        return self.vc.messageAPI.createInvite(recipient.alias).then { invite -> Promise<Any?> in
//          
//          guard let invite = invite as? RTInvite else {
//            return Promise(error: Error.Failed)
//          }
//          
//          let composer = MFMailComposeViewController()
//          
//          composer.setToRecipients([recipient.alias])
//          composer.setSubject(invite.subject)
//          composer.setMessageBody(invite.bodyHtml ?? invite.bodyText, isHTML: invite.bodyHtml != nil)
//          
//          return self.vc.promiseViewController(composer).then { result -> Any? in
//            
//            return true
//          }
//          
//        }
//          
//        }
//      
//      }
//      .recover { error -> Promise<Any?> in
//      
//        switch error {
//          
//        case Error.CannotSendSMS:
//          return self.showErrorAlertWithTitle("Invite",
//            message: "Unfortunately your device is not setup to send SMS messages.")
//          
//        case Error.CannotSendEmail:
//          return self.showErrorAlertWithTitle("Invite",
//            message: "Unfortunately your device is not setup to send e-mail messages.")
//          
//        case let err as CancellableErrorType:
//          if err.cancelled {
//            return Promise(true)
//          }
//          fallthrough
//          
//        default:
//          return self.showErrorAlertWithTitle("Invite",
//            message: "An error occurred trying to invite. Please try again.")
//        }
//        
//      }
//      .always {
//        
//        self.finish()
//          
//      }
      
    }
    
  }
  
  func showErrorAlertWithTitle(title: String, message: String) -> Promise<Any?> {
    
    let warn = PMKAlertController(title: title, message: message, preferredStyle: .Alert)
    
    warn.addActionWithTitle("Ok", style: .Default)
    
    return self.vc.promiseViewController(warn).then { result -> Any? in
      return result
    }
    
  }
  
}
