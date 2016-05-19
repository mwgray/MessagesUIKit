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
    
    switch launchEnvironment["testTarget"] ?? "none" {
    case "summaries":
      
      let dbPath = NSBundle(forClass: AppDelegate.self).pathForResource("test", ofType: "db")!
      let dbManager = try! DBManager(path: dbPath, kind: "Messages", daoClasses: [MessageDAO.self, ChatDAO.self])
      
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

