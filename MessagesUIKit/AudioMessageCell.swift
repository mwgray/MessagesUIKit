//
//  AudioMessageCell.swift
//  ReTxt
//
//  Created by Kevin Wooten on 10/14/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import MessagesKit
import CocoaLumberjack


protocol AudioMessageCellDelegate : MessageCellDelegate {
  
  func checkAudioPlayingWithKey(key: String) -> Bool
  func progressOfAudioPlayingWithKey(key: String) -> CGFloat
  
}


class AudioMessageCell : MessageCell {
  
  
  @IBOutlet var playbackButton : UIButton!
  @IBOutlet var audioPlot : AudioPlot!
  @IBOutlet var durationLabel : UILabel!
  @IBOutlet var loadingView : UIActivityIndicatorView!
  
  
  static let timeFormatter : NSDateComponentsFormatter = {
    let formatter = NSDateComponentsFormatter()
    formatter.unitsStyle = .Positional
    return formatter
  }()
  
  
  var audioDelegate : AudioMessageCellDelegate {
    return super.delegate as! AudioMessageCellDelegate
  }
  
  override func willBeginDisplaying() {
    super.willBeginDisplaying()
  }
  
  override func updateWithMessage(message: Message) {

    guard let message = message as? AudioMessage else {
      fatalError("invalid message class")
    }
    
    super.updateWithMessage(message)
    
    let clipKey = message.id.UUIDString() + "@clip"
    
    // Update playback progress with current playing state
    audioPlot.progress = audioDelegate.progressOfAudioPlayingWithKey(clipKey)
    
    // Update playback button image with current playing state
    let playbackImage = audioDelegate.checkAudioPlayingWithKey(clipKey) ?
      UIImage(id: .AudioPlay) : UIImage(id: .AudioPause)
    
    playbackButton.setImage(playbackImage, forState: .Normal)

    let neededSampleCount = audioPlot.sampleCount
    
    if let audioFile = delegate.loadCachedMediaForKey(clipKey, loader: { resolve, fail in
    
      DDLogDebug("Caching audio clip \(message.id.UUIDString)")
      
      //FIXME: 
      //let audioURL = DataReferences.duplicateDataReferenceToTemporaryFile(message.data, withExtension: "m4a").URL
      //let audioFile = AudioFile(URL: audioURL)
      
      let audioFile = AudioFile(URL: NSURL())
      
      do {
        try audioFile.open()
      }
      catch let error {
        fail(error as NSError)
        return
      }
    
      audioFile.generateSampleData(neededSampleCount, completion: {
      
        //FIXME: resolve(message.dataURL, audioFile, audioFile.size)
        
      }, error: { error in
        
        DDLogError("Error generating audio samples \(error)")
        
        fail(error)
        
      })
      
    }) as? AudioFile {
      
      if audioFile.hasSamples {
        audioPlot.hidden = false
        audioPlot.updateSamples(audioFile.samples, count: audioFile.sampleCount)
      }
      
      durationLabel.text = AudioMessageCell.timeFormatter.stringFromTimeInterval(audioFile.duration)
      
    }
    else {
      
      loadingView.startAnimating()
      
    }
    
  }
  
  override func mediaAvailableWithInfo(info: [String : AnyObject]) {
    
    guard let
      samples = info[MessageCellMediaDataAvailableNotificationAudioSamples] as? UnsafeMutablePointer<Float>,
      sampleCount = info[MessageCellMediaDataAvailableNotificationAudioSampleCount] as? UInt,
      duration = info[MessageCellMediaDataAvailableNotificationDuration] as? NSTimeInterval
    else {
      return
    }

    audioPlot.hidden = false
    audioPlot.updateSamples(samples, count: sampleCount)
    
    durationLabel.text = AudioMessageCell.timeFormatter.stringFromTimeInterval(duration)
  }
  
  override func mediaPlayProgressWithInfo(info: [String : AnyObject]) {
    
    guard let
      percent = info[MessageCellMediaPlayProgressNotificationPercentKey] as? CGFloat,
      status = info[MessageCellMediaPlayProgressNotificationStatusKey] as? MessageCellMediaPlayStatus
    else {
      return
    }
    
    audioPlot.progress = percent
      
    switch status {
    case .Paused, .Stopped:
      playbackButton.setImage(UIImage(id: .AudioPause), forState: .Normal)
      
    case .Playing:
      playbackButton.setImage(UIImage(id: .AudioPlay), forState: .Normal)
    }
    
  }
  
}
