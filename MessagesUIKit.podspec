Pod::Spec.new do |s|
  s.name = 'MessagesUIKit'
  s.version = '0.1'
  s.summary = 'reTXT messaging UI framework for iOS/OSX'
  s.homepage = 'https://github.com/reTXT/MessagesUIKit'
  s.license = 'MIT'
  s.author = { 'Kevin Wooten' => 'kevin@retxt.com' }
  s.source = { :git => 'https://github.com/reTXT/MessagesUIKit.git', :tag => "#{s.version}" }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  
  s.source_files = 'MessagesUIKit/*.{h,m,swift}'
  s.resources = 'MessagesUIKit/*.xib','MessagesUIKit/*.xcassets'

  s.dependency 'MessagesKit'
  s.dependency 'CocoaLumberjack/Swift'
  s.dependency 'SnapKit'
  s.dependency 'TURecipientBar'
  
end
