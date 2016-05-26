platform :ios, '8.0'

use_frameworks!

target :MessagesUIKit do
  
  pod 'OpenSSLCrypto', :git => 'https://github.com/reTXT/OpenSSLCrypto.git'
  
  pod 'FMDB/standalone/swift', :git => 'https://github.com/reTXT/fmdb.git', :branch => 'current'
  pod 'FMDBMigrationManager', :git => 'https://github.com/reTXT/FMDBMigrationManager.git', :branch => 'master'
  pod 'YOLOKit', :git => 'https://github.com/reTXT/YOLOKit.git', :branch => 'master'
  
  pod 'PSOperations/Core', :git => 'https://github.com/reTXT/PSOperations.git', :branch => 'current'
  pod 'PSOperations/SystemConfiguration', :git => 'https://github.com/reTXT/PSOperations.git', :branch => 'current'
  
  pod 'Thrift', :git => 'https://github.com/reTXT/thrift.git', :branch => 'master'
  pod 'PromiseKit/DietFoundation', :git => 'https://github.com/reTXT/PromiseKit.git', :branch => 'master'
  pod 'PromiseKit/AddressBook', :git => 'https://github.com/reTXT/PromiseKit.git', :branch => 'master'
  pod 'PromiseKit/AssetsLibrary', :git => 'https://github.com/reTXT/PromiseKit.git', :branch => 'master'
  pod 'PromiseKit/AVFoundation', :git => 'https://github.com/reTXT/PromiseKit.git', :branch => 'master'

  pod 'TURecipientBar', :git => 'https://github.com/reTXT/TURecipientBar.git', :branch => 'master'
  
  pod 'MessagesKit', :path => '../MessagesKit' #:git => 'https://github.com/reTXT/MessagesKit.git', :branch => 'master'
  
  pod 'CocoaLumberjack/Swift'
  pod 'SnapKit'
  
  target :MessagesUIKitTests do
    pod 'JPSimulatorHacks', :git => 'https://github.com/reTXT/JPSimulatorHacks.git'
  end

  target :MessagesUIKitHost do
    pod 'JPSimulatorHacks', :git => 'https://github.com/reTXT/JPSimulatorHacks.git'
  end
  
end
