//
//  AppDelegate.swift
//  MessagesUIKitHost
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import UIKit
import MessagesKit
import MessagesUIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    window = UIWindow()
    
    let launchEnvironment = NSProcessInfo.processInfo().environment
    
    let dbName = launchEnvironment["testData"] ?? "test"
    let dbPath = NSBundle(forClass: AppDelegate.self).pathForResource(dbName, ofType: "db")!
    let dbManager = try! DBManager(path: dbPath, kind: "Messages", daoClasses: [MessageDAO.self, ChatDAO.self])
    
    switch launchEnvironment["testTarget"] ?? "messages" {
    case "messages":
      
      let request = FetchRequest()
      request.resultClass = Message.self
      request.predicate = NSPredicate(value: true)
      request.includeSubentities = true
      request.sortDescriptors = [NSSortDescriptor(key: "sent", ascending: true)]
      request.fetchOffset = 0
      request.fetchLimit = 0
      request.fetchBatchSize = 0
      
      let messageResultsController = FetchedResultsController(DBManager: dbManager, request: request)
      
      try! messageResultsController.execute()
      
      let mvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Messages") as! MessagesViewController
      mvc.messageResultsController = messageResultsController
      
      window?.rootViewController = UINavigationController(rootViewController: mvc)
      
    case "summaries":
      
      let request = FetchRequest()
      request.resultClass = Chat.self
      request.predicate = NSPredicate(value: true)
      request.includeSubentities = true
      request.sortDescriptors = []
      request.fetchOffset = 0
      request.fetchLimit = 0
      request.fetchBatchSize = 0
      
      let chatResultsController = FetchedResultsController(DBManager: dbManager, request: request)
      
      try! chatResultsController.execute()

      let csvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RecentChats") as! ChatSummariesViewController
      csvc.chatResultsController = chatResultsController
      
      window?.rootViewController = UINavigationController(rootViewController: csvc)
      
    default:
      window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
    }

    window?.makeKeyAndVisible()

    return true
  }

}

