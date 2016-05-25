//
//  RecentChatsViewController.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 9/15/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import UIKit
import MessagesKit


public class ChatSummariesViewController : UITableViewController, FetchedResultsControllerDelegate {
  
  public var chatResultsController : FetchedResultsController? {
    willSet {
      chatResultsController?.delegate = nil
    }
    didSet {
      chatResultsController?.delegate = self
    }
  }
  
  let receivedDateFormatter = RelativeHistoryDateFormatter()
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.estimatedRowHeight = 50;
    
  }
  
  func configureCell(cell: ChatSummaryTableViewCell, atIndexPath indexPath: NSIndexPath) {
    
    let chat = self.chatResultsController![indexPath.row] as! Chat
    
    if cell.title == nil {
      cell.title = AliasDisplayTitle(memberAliases: Array(chat.activeRecipients), aliasDisplayProvider: AliasDisplayManager.sharedProvider, separator: ", ")
    }
    
    cell.senderLabel.text = cell.title?.full(leadingMember: chat.lastMessage?.sender ?? "") ?? ""
    
    let hasUnread : Bool
    
    if let lastMessage = chat.lastMessage {
      
      cell.summaryLabel.text = lastMessage.summaryText()
      
      cell.dateLabel.text = receivedDateFormatter.stringFromDate(lastMessage.sent ?? NSDate())
      
      hasUnread = lastMessage.unreadFlag && !lastMessage.sentByMe
      
    }
    else {
      
      let italicFont = cell.summaryLabel.font.italic()
      
      cell.summaryLabel.attributedText = NSAttributedString(string: "No messages", attributes:[NSFontAttributeName : italicFont])
      
      hasUnread = false
    }
    
    if (chat.clarifiedCount > 0 && chat.updatedCount <= 0 && !hasUnread) {
      cell.notificationDotView.hidden = false
      cell.notificationDotView.backgroundColor = InternalStyle.brandBlack
    }
    else if (chat.clarifiedCount <= 0 && chat.updatedCount > 0) {
      cell.notificationDotView.hidden = false
      cell.notificationDotView.backgroundColor = InternalStyle.brandGreen
    }
    else if (hasUnread) {
      cell.notificationDotView.hidden = false
      cell.notificationDotView.backgroundColor = InternalStyle.brandYellow
    }
    else {
      cell.notificationDotView.hidden = true
    }
    
  }
  
  // MARK: Table view data source
  
  public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
    return 1
  }
  
  public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return self.chatResultsController?.numberOfObjects() ?? 0
  }
  
  public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCellWithIdentifier("ChatSummary", forIndexPath: indexPath) as! ChatSummaryTableViewCell
  
    configureCell(cell, atIndexPath: indexPath)
  
    return cell
  }
  
  public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    
    let chat = self.chatResultsController![indexPath.row] as! Chat

    var actions = [UITableViewRowAction]()
    
    if let group = chat as? GroupChat {
      
      actions.append(
        UITableViewRowAction(style: .Default, title: group.includesMe ? "Leave" : "Return", handler: { row, indexPath in
          
        })
      )
      
    }
    
    actions.append(
      UITableViewRowAction(style: .Destructive, title: "Delete", handler: { row, indexPath in
        
      })
    )
    
    return actions
  }
  
  // MARK: Fetched Results Controller
  
  public func controllerWillChangeResults(controller: FetchedResultsController) {
    tableView.beginUpdates()
  }
  
  public func controller(controller: FetchedResultsController, didChangeObject object: AnyObject, atIndex index: Int, forChangeType changeType: FetchedResultsChangeType, newIndex: Int) {
    
    let indexPath = NSIndexPath(forRow: index, inSection: 0)
    let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
    
    switch changeType {
      
    case .Insert:
      
      tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
      
    case .Update:
      
      if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ChatSummaryTableViewCell {
        configureCell(cell, atIndexPath: indexPath)
      }
      
    case .Move:
      
      if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ChatSummaryTableViewCell {
        configureCell(cell, atIndexPath: indexPath)
      }

      if let cell = tableView.cellForRowAtIndexPath(newIndexPath) as? ChatSummaryTableViewCell {
        configureCell(cell, atIndexPath: newIndexPath)
      }
      
      tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
      
    case .Delete:
      
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      
    }
    
  }
  
  public func controllerDidChangeResults(controller: FetchedResultsController) {
    tableView.endUpdates()
  }
  
}
