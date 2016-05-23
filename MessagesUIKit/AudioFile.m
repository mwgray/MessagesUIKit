//
//  AudioFile.m
//  ReTxt
//
//  Created by Kevin Wooten on 8/6/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "AudioFile.h"

@import MessagesKit;
@import AVFoundation;


MK_DECLARE_LOG_LEVEL()


NSError *checkStatus(OSStatus status);


typedef SInt32 LocalAudioSampleType;


@interface AudioFile () {
  float *_samples;
  ExtAudioFileRef _audioFile;
  AudioStreamBasicDescription _fileFormat;
}

@end



@implementation AudioFile

-(instancetype) initWithURL:(NSURL *)url
{
  self = [super init];
  if (self) {

    _url = url;
    _audioFile = NULL;
    _hasSamples = NO;
    _samples = NULL;
    _sampleCount = 0;
    
  }
  return self;
}

-(void) dealloc
{
  if (_samples) {
    free(_samples);
    _samples = NULL;
  }

  if (_audioFile) {
    NSError *error = checkStatus(ExtAudioFileDispose(_audioFile));
    if (error) {
      DDLogError(@"Error disposing audio file: %@", error);
    }
    _audioFile = NULL;
  }
}

-(BOOL) openWithError:(NSError **)error
{
  NSError *localError;

  localError = checkStatus(ExtAudioFileOpenURL((__bridge CFURLRef)_url, &_audioFile));
  if (localError) {
    if (error) {
      *error = localError;
    }
    return NO;
  }

  UInt32 propertySize;

  propertySize = sizeof(_fileFormat);
  localError = checkStatus(ExtAudioFileGetProperty(_audioFile, kExtAudioFileProperty_FileDataFormat, &propertySize, &_fileFormat));
  if (localError) {

    ExtAudioFileDispose(_audioFile);
    _audioFile = NULL;
    
    if (error) {
      *error = localError;
    }
    return NO;
  }

  propertySize = sizeof(_totalFrames);
  localError = checkStatus(ExtAudioFileGetProperty(_audioFile, kExtAudioFileProperty_FileLengthFrames, &propertySize, &_totalFrames));
  if (localError) {
    
    ExtAudioFileDispose(_audioFile);
    _audioFile = NULL;

    if (error) {
      *error = localError;
    }
    return NO;
  }

  // Sanity check
  if (_totalFrames > UINT32_MAX) {
    _totalFrames = 0;
  }

  _size = _fileFormat.mBytesPerPacket * _fileFormat.mSampleRate;
  _duration = _totalFrames / _fileFormat.mSampleRate;

  return YES;
}


#define ERROR_RETURN(error) {if (errorCall) {errorCall(error); } return; }

-(void) generateSampleData:(NSUInteger)requestedSamples completion:(void (^)())completion error:(void (^)(NSError *error))errorCall
{
  if (!completion) {
    return;
  }

  if (!_audioFile) {
    errorCall([NSError errorWithDomain:@"AudioFileErrorDomain" code:0 userInfo:@{@"reason": @"file not open"}]);
    return;
  }

  // Is there any data?
  if (_totalFrames == 0) {
    completion();
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

    @synchronized(self) {

      if (_hasSamples) {
        completion();
        return;
      }

      NSError *error = nil;

      AudioStreamBasicDescription audioReadFormat;
      UInt32 byteSize = sizeof(LocalAudioSampleType);
      audioReadFormat.mBitsPerChannel   = 8 * byteSize;
      audioReadFormat.mBytesPerFrame    = byteSize;
      audioReadFormat.mBytesPerPacket   = byteSize;
      audioReadFormat.mChannelsPerFrame = 1;
      audioReadFormat.mFormatFlags      = kAudioFormatFlagIsPacked|kAudioFormatFlagIsFloat;
      audioReadFormat.mFormatID         = kAudioFormatLinearPCM;
      audioReadFormat.mFramesPerPacket  = 1;
      audioReadFormat.mSampleRate       = _fileFormat.mSampleRate;

      UInt32 propertySize = sizeof(audioReadFormat);
      error = checkStatus(ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_ClientDataFormat, propertySize, &audioReadFormat));
      if (error) {
        ERROR_RETURN(error);
      }

      UInt32 totalFrames = (UInt32)_totalFrames;

      UInt32 waveformFrameRate = (totalFrames + (UInt32)requestedSamples - 1) / requestedSamples;
      
      float *waveformData = malloc(sizeof(float)*requestedSamples);

      AudioBufferList *bufferList = [AudioFile audioBufferListWithNumberOfFrames:waveformFrameRate
                                                                numberOfChannels:audioReadFormat.mChannelsPerFrame
                                                                     interleaved:YES];

      for (int i = 0; i < requestedSamples; i++) {

        // Take a snapshot of each buffer through the audio file to form the
        //  waveform
        UInt32 bufferSize;

        // Read in the specified number of frames
        NSError *readError = checkStatus(ExtAudioFileRead(_audioFile, &waveformFrameRate, bufferList));
        if (readError) {
          [AudioFile freeBufferList:bufferList];
          free(waveformData);
          ERROR_RETURN(readError);
        }

        bufferSize = bufferList->mBuffers[0].mDataByteSize/sizeof(LocalAudioSampleType);
        bufferSize = MAX(1, bufferSize);

        // Calculate RMS of each buffer
        waveformData[i] = [AudioFile RMS:bufferList->mBuffers[0].mData length:bufferSize];
      }

      [AudioFile freeBufferList:bufferList];

      _samples = waveformData;
      _sampleCount = requestedSamples;

      _hasSamples = YES;

      completion();

    }

  });

}

+(AudioBufferList *) audioBufferListWithNumberOfFrames:(UInt32)frames
                                      numberOfChannels:(UInt32)channels
                                           interleaved:(BOOL)interleaved
{
  AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
  UInt32 outputBufferSize = 32 * frames; // 32 KB
  audioBufferList->mNumberBuffers = interleaved ? 1 : channels;
  for (int i = 0; i < audioBufferList->mNumberBuffers; i++) {
    audioBufferList->mBuffers[i].mNumberChannels = channels;
    audioBufferList->mBuffers[i].mDataByteSize = channels * outputBufferSize;
    audioBufferList->mBuffers[i].mData = (LocalAudioSampleType *)malloc(channels * sizeof(LocalAudioSampleType) *outputBufferSize);
  }
  return audioBufferList;
}

+(void) freeBufferList:(AudioBufferList *)bufferList
{
  if (bufferList) {
    if (bufferList->mNumberBuffers) {
      for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        if (bufferList->mBuffers[i].mData) {
          free(bufferList->mBuffers[i].mData);
        }
      }
    }
    free(bufferList);
  }
  bufferList = NULL;
}

+(float) RMS:(float *)buffer length:(int)bufferSize
{
  float sum = 0.0;
  for (int i = 0; i < bufferSize; i++) {
    sum += buffer[i] * buffer[i];
  }
  return sqrtf(sum / bufferSize);
}

@end


NSError *checkStatus(OSStatus status)
{
  if (status == noErr) {
    return nil;
  }

  char errorString[20] = {0};

  // see if it appears to be a 4-char-code
  *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(status);

  if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
    errorString[0] = errorString[5] = '\'';
    errorString[6] = '\0';
  }
  else {
    // no, format it as an integer
    sprintf(errorString, "%d", (int)status);
  }

  return [NSError errorWithDomain:NSOSStatusErrorDomain
                             code:status
                         userInfo:@{@"status":[NSString stringWithUTF8String:errorString]}];
}
