//
//  NSDate.swift
//  MessagesUIKit
//
//  Created by Kevin Wooten on 5/16/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import Foundation


public class RelativeHistoryDateFormatter : NSFormatter {
  
  private let internalFormatter = NSDateFormatter()
  private let locale = NSLocale.autoupdatingCurrentLocale()
  private let calendar = NSCalendar.autoupdatingCurrentCalendar()
  
  public override init() {
    super.init()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init()
  }
  
  public override func stringForObjectValue(obj: AnyObject) -> String? {
    
    guard let date = obj as? NSDate else {
      return nil
    }
   
    return stringFromDate(date)
  }
  
  public func stringFromDate(date: NSDate) -> String? {
    
    var approxFormat = ""
    
    if !date.isToday {
      
      guard let sevenDaysAgo = date.startOfLastWeekUsingCalendar(calendar) else {
        return nil
      }
      
      if date.isBetweenDate(sevenDaysAgo, andDate: NSDate()) {
        approxFormat += "EEEE"
      }
      else {
        // Use proper date
        approxFormat = "EEE MMM dd"
      }
      
    }
    
    approxFormat += " h:mm a"
    
    guard let format = NSDateFormatter.dateFormatFromTemplate(approxFormat, options: 0, locale: locale) else {
      return nil
    }
    
    internalFormatter.dateFormat = format
    return internalFormatter.stringFromDate(date)
  }
  
}


extension NSDate {
  
  private func startOfLastWeekUsingCalendar(calendar: NSCalendar) -> NSDate? {
    
    guard let startOfDay = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: NSDate())) else {
      return nil
    }
    
    guard let endOfDay = calendar.dateByAddingUnit(.Day, value: 1, toDate: startOfDay, options: []) else {
      return nil
    }
    
    return calendar.dateByAddingUnit(.WeekOfYear, value: -1, toDate: endOfDay, options: [])
  }

}
