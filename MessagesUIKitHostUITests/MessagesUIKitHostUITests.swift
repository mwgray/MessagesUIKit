//
//  MessagesUIKitHostUITests.swift
//  MessagesUIKitHostUITests
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import XCTest

class MessagesUIKitHostUITests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    continueAfterFailure = false
    
    let app = XCUIApplication()
    
    app.launchEnvironment["testTarget"] = "messages";
    
    app.launch()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testExample() {
  }
  
}
