//
//  RTMessagesViewLayout.swift
//  ReTxt
//
//  Created by Kevin Wooten on 6/10/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import UIKit


class MessagesViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext {
  
  var interactiveActionMenuDragItemIndexPath : NSIndexPath?
  var interactiveActionMenuDragActionMenuSize : CGSize?
  var interactiveActionMenuDragDistance : CGFloat?
  var interactiveActionMenuDragQuickEnabled : Bool?
  
}

enum MessagesViewCellPlacement {
  case LeftAlign, RightAlign, Flow
}

enum MessagesViewCellOrnament : String {
  case SenderHeader
  case TimeHeader
  case StatusFooter
  case Clarify
  case ActionMenu
  case Quote
}

class MessagesViewLayoutAttributes : UICollectionViewLayoutAttributes {
  
  var ornaments : Set<MessagesViewCellOrnament>?
  var placement : MessagesViewCellPlacement?
  var margins = UIEdgeInsets()
  
  var totalHeight : CGFloat {
    return size.height + margins.totalVertical
  }
  
  var alignmentRectInsets : UIEdgeInsets?
  
  override func copyWithZone(zone: NSZone) -> AnyObject {
    let copy = super.copyWithZone(zone) as! MessagesViewLayoutAttributes
    copy.ornaments = ornaments
    copy.placement = placement
    copy.margins = margins
    copy.alignmentRectInsets = alignmentRectInsets
    return copy
  }
  
  override func isEqual(object: AnyObject?) -> Bool {
    
    if super.isEqual(object) {
      let object = object as! MessagesViewLayoutAttributes
      return
        (self.ornaments == object.ornaments) &&
        (self.placement == object.placement) &&
        (self.margins == object.margins) &&
        (self.alignmentRectInsets == object.alignmentRectInsets)
    }
    
    return false
  }
  
}



protocol MessagesViewLayoutDelegate {
  
  func collectionView(collectionView: UICollectionView, messagesLayout: MessagesViewLayout, ornamentsForItemAtIndexPath: NSIndexPath) -> Set<MessagesViewCellOrnament>
  func collectionView(collectionView: UICollectionView, messagesLayout: MessagesViewLayout, placementForItemAtIndexPath indexPath: NSIndexPath) -> MessagesViewCellPlacement
  
}


class MessagesViewLayout: UICollectionViewLayout {
  
  private enum Direction {
    case Backward
    case Forward
  }
  
  
  private class CellAttributes {
    
    var yPosition : CGFloat
    var size : CGSize
    var lineHeight : CGFloat?
    var alignmentRectInsets : UIEdgeInsets?
    var placement : MessagesViewCellPlacement?
    var ornaments : Set<MessagesViewCellOrnament>?
    var actionMenuDragOffset : CGFloat?
    var actionMenuDragDistance : CGFloat?
    var margins : UIEdgeInsets
    
    var minY : CGFloat {
      return yPosition
    }
    
    var maxY : CGFloat {
      return yPosition + totalHeight
    }
    
    var totalHeight : CGFloat {
      return size.height + margins.totalVertical
    }
    
    var totalWidth : CGFloat {
      return size.width + margins.totalHorizontal
    }
    
    init(yPosition: CGFloat, size: CGSize, margins: UIEdgeInsets) {
      self.yPosition = yPosition
      self.size = size
      self.margins = margins
    }
    
  }
  
  private class OrnamentAttributes {
    var size : CGSize
    
    init(size: CGSize) {
      self.size = size
    }
    
  }
  
  
  let estimatedCellSize = CGSize(width: 50, height: 60)
  let estimatedActionMenuSize = CGSize(width: 100, height: 44)
  let estimatedClarifyIconSize = CGSize(width: 22, height: 22)
  let estimatedTimeHeaderSize = CGSize(width: 100, height: 40)
  let estimatedSenderHeaderSize = CGSize(width: 150, height: 30)
  let estimatedStatusFooterSize = CGSize(width: 60, height: 12)
  
  
  @IBInspectable var cellMargins = UIEdgeInsets()
  
  private var initialized = false
  private var delegate : MessagesViewLayoutDelegate?
  private var currentContentSize = CGSize()
  
  private var totalItems = 0
  private var sectionItemCounts = [Int]()
  
  private var cellAttributes = [NSIndexPath: CellAttributes]()
  private var ornamentAttributes = [MessagesViewCellOrnament: [NSIndexPath: OrnamentAttributes]]()
  
  private var activeRangeRect : CGRect?
  private var activeRangeStart : NSIndexPath?
  private var activeRangeEnd : NSIndexPath?
  
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override class func layoutAttributesClass() -> AnyClass {
    return MessagesViewLayoutAttributes.self
  }
  
  override class func invalidationContextClass() -> AnyClass {
    return MessagesViewLayoutInvalidationContext.self
  }
  
  func invalidationContextForInteractivelyDraggingActionMenuAtIndexPath(indexPath: NSIndexPath) -> MessagesViewLayoutInvalidationContext {
    
    let context = MessagesViewLayoutInvalidationContext()
    
    context.interactiveActionMenuDragItemIndexPath = indexPath
    context.interactiveActionMenuDragActionMenuSize = ornamentAttributes[.ActionMenu]?[indexPath]?.size
    context.interactiveActionMenuDragDistance = cellAttributes[indexPath]?.actionMenuDragDistance
    
    return context
  }
  
  func invalidationContextForEndingInteractiveDraggingOfActionMenuAtIndexPath(indexPath: NSIndexPath) -> MessagesViewLayoutInvalidationContext {
    
    let context = MessagesViewLayoutInvalidationContext()
    
    context.interactiveActionMenuDragItemIndexPath = indexPath
    context.interactiveActionMenuDragActionMenuSize = ornamentAttributes[.ActionMenu]?[indexPath]?.size
    
    return context
  }
  
  override func invalidateLayoutWithContext(context: UICollectionViewLayoutInvalidationContext) {
    
    if context.invalidateEverything {
      initialized = false
      
      return
    }
    
    let invalidator = MessagesViewLayoutInvalidator()
    
    // Update items for fine-grained invalidation requests
    
    if let itemIndexPaths = context.invalidatedItemIndexPaths {
      
      for itemIndexPath in itemIndexPaths {
        
        if let cellAttrs = cellAttributes[itemIndexPath] {
          let layoutAttrs = generateLayoutAttributesForItemAtIndexPath(itemIndexPath, withCellAttributes: cellAttrs)
          refreshCellAttributes(cellAttrs, forItemAtIndexPath: itemIndexPath)
          calculateInvalidationContext(invalidator, forCellAttributes: cellAttrs, originalAttributes: layoutAttrs)
        }
      }
      
    }
    
    let context = context as! MessagesViewLayoutInvalidationContext
    
    // Process action menu drag invalidation
    
    if let
      interactiveActionMenuDragItemIndexPath = context.interactiveActionMenuDragItemIndexPath,
      cellAttrs = cellAttributes[interactiveActionMenuDragItemIndexPath] {
    
        if cellAttrs.actionMenuDragOffset == nil {
          cellAttrs.actionMenuDragOffset =
            cellAttrs.ornaments?.contains(.ActionMenu) ?? false ?
              ornamentAttributes[.ActionMenu]?[interactiveActionMenuDragItemIndexPath]?.size.width ?? 0 : 0
        }
        
        invalidator.invalidateItemAtIndexPath(interactiveActionMenuDragItemIndexPath)
        invalidator.invalidateOrnament(.ActionMenu, atIndexPath: interactiveActionMenuDragItemIndexPath)
        cellAttrs.ornaments?.forEach { invalidator.invalidateOrnament($0, atIndexPath: interactiveActionMenuDragItemIndexPath) }
        
        let layoutAttrs = generateLayoutAttributesForItemAtIndexPath(interactiveActionMenuDragItemIndexPath, withCellAttributes: cellAttrs)
        
        if let distance = context.interactiveActionMenuDragDistance {
          cellAttrs.actionMenuDragDistance = distance
          cellAttrs.ornaments?.insert(.ActionMenu)
        }
        else {
          cellAttrs.actionMenuDragOffset = nil
          cellAttrs.actionMenuDragDistance = nil
          cellAttrs.ornaments?.remove(.ActionMenu)
          refreshCellAttributes(cellAttrs, fromDelegateForItemAtIndexPath: interactiveActionMenuDragItemIndexPath, forced: true)
        }
        
        recalculateDependenciesForCellAttributes(cellAttrs, forItemAtIndexPath: interactiveActionMenuDragItemIndexPath)
        
        calculateInvalidationContext(invalidator, forCellAttributes: cellAttrs, originalAttributes: layoutAttrs)
    }

    // Generate final invalidation context
    
    let finalContext = invalidator.commit(context)
    
    currentContentSize += finalContext.contentSizeAdjustment
    
    super.invalidateLayoutWithContext(finalContext)
  }
  
  func initializeLayout() {
    
    delegate = collectionView!.delegate as? MessagesViewLayoutDelegate
    assert(delegate != nil)
    
    let totalSections = collectionView!.numberOfSections()
    
    totalItems = 0
    sectionItemCounts = [Int](count: totalSections, repeatedValue: 0)
    
    for section in 0..<sectionItemCounts.count {
      
      let sectionItemCount = collectionView!.numberOfItemsInSection(section)
      
      sectionItemCounts[section] = sectionItemCount
      
      totalItems += sectionItemCount
    }
    
    currentContentSize.width = collectionView!.frame.width
    currentContentSize.height = CGFloat(totalItems) * (estimatedCellSize.height + cellMargins.totalVertical)
    
    activeRangeStart = nil
    activeRangeEnd = nil
    activeRangeRect = nil
    
    cellAttributes.removeAll(keepCapacity: true)
    ornamentAttributes[MessagesViewCellOrnament.ActionMenu] = [NSIndexPath: OrnamentAttributes]()
    ornamentAttributes[MessagesViewCellOrnament.TimeHeader] = [NSIndexPath: OrnamentAttributes]()
    ornamentAttributes[MessagesViewCellOrnament.SenderHeader] = [NSIndexPath: OrnamentAttributes]()
    ornamentAttributes[MessagesViewCellOrnament.Clarify] = [NSIndexPath: OrnamentAttributes]()
    ornamentAttributes[MessagesViewCellOrnament.StatusFooter] = [NSIndexPath: OrnamentAttributes]()
  }
  
  override func prepareLayout() {
    super.prepareLayout()
    
    if !initialized {
      
      initializeLayout()
      
      initialized = true
    }

  }
  
  override func collectionViewContentSize() -> CGSize {
    return currentContentSize
  }
  
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    
    if sectionItemCounts.count == 1 && sectionItemCounts[0] == 0 {
      return []
    }
    
    if rect.maxY == 9338 {
      print("here")
    }
    
    let prevActiveRangeRect = activeRangeRect
    let prevActiveRangeStart = activeRangeStart
    let prevActiveRangeEnd = activeRangeEnd
    
    // Pick high quality starting point
    
    let startIndexPath : NSIndexPath
    var currentY : CGFloat
    let layoutDirection : Direction
    
    if let lastActiveRangeRect = activeRangeRect {
      
      if rect.midY < lastActiveRangeRect.midY {
        layoutDirection = .Backward
        startIndexPath = activeRangeEnd!
        
        guard let startAttrs = cellAttributes[startIndexPath] else {
          fatalError("inconsistency")
        }
        
        currentY = startAttrs.maxY
      }
      else {
        layoutDirection = .Forward
        startIndexPath = activeRangeStart!
        
        guard let startAttrs = cellAttributes[startIndexPath] else {
          fatalError("inconsistency")
        }
        
        currentY = startAttrs.minY
      }
      
      activeRangeRect = nil
      activeRangeStart = nil
      activeRangeEnd = nil
    }
    else {
      
      let estimatedTotalHeight = estimatedCellSize.height + cellMargins.totalVertical
      
      // Figure out shorter distance, to top or to bottom, and start
      // initial layout from that closest edge
      
      if rect.midY < (currentContentSize.height/2) {
        
        let absoluteIndex = max(Int(rect.minY / estimatedTotalHeight), 0)
        
        startIndexPath = indexPathFromAbsoluteIndex(absoluteIndex)
        
        currentY = CGFloat(absoluteIndex) * estimatedTotalHeight
        
        layoutDirection = .Forward
      }
      else {
        
        let absoluteIndex = min(Int(rect.maxY / estimatedCellSize.height), totalItems-1)
        
        startIndexPath = indexPathFromAbsoluteIndex(absoluteIndex)
        
        currentY = CGFloat(absoluteIndex + 1) * estimatedTotalHeight
        
        layoutDirection = .Backward
      }
    }
    
    print("dir=\(layoutDirection) from=\(rect.minY/667) to=\(rect.maxY/667) total=\(rect.size.height/667) contentSize=\(currentContentSize.width),\(currentContentSize.height)")
    
    let items =  performLayoutForElementsInRect(rect, startIndexPath: startIndexPath, currentY: currentY, direction: layoutDirection)
    
    if activeRangeStart != nil && activeRangeEnd != nil {
      activeRangeRect = rect
    }
    else {
      activeRangeRect = prevActiveRangeRect
      activeRangeStart = prevActiveRangeStart
      activeRangeEnd = prevActiveRangeEnd
    }
    
    return items
  }
  
  /**
   
   Layout algorithm
   
   - Parameters:
   - rect: Rectangle to be laid out
   - startIndexPath: Index path to begin layout with
   - currentY: Y location corresponding to startIndexPath
   - direction: Layout direction to apply
   
   - Result: Array of layout attributes
   */
  private func performLayoutForElementsInRect(rect: CGRect, startIndexPath: NSIndexPath, currentY: CGFloat, direction: Direction) -> [UICollectionViewLayoutAttributes] {
    
    var result = [UICollectionViewLayoutAttributes]()
    
    var flowLine = MessagesViewLayoutFlowLine(maxWidth: collectionView!.frame.width, direction: direction)
    
    let advanceIndexPath : (NSIndexPath) -> NSIndexPath?
    let advanceYPre : (CGFloat) -> CGFloat
    let advanceYPost : (CGFloat) -> CGFloat
    let markReturnedSectionBegan : (NSIndexPath?) -> Void
    let markReturnedSectionEnded : (NSIndexPath?) -> Void
    let hasReturnedSectionBegan : () -> Bool
    
    if direction == .Backward {
      advanceIndexPath = previousIndexPath
      advanceYPre = { height in -height }
      advanceYPost = { height in 0 }
      markReturnedSectionBegan = { mark in
        if self.activeRangeEnd == nil {
          self.activeRangeEnd = mark
        }
      }
      markReturnedSectionEnded = { mark in self.activeRangeStart = mark }
      hasReturnedSectionBegan = { self.activeRangeEnd != nil }
    }
    else {
      advanceIndexPath = nextIndexPath
      advanceYPre = { height in 0 }
      advanceYPost = { height in height }
      markReturnedSectionBegan = { mark in
        if self.activeRangeStart == nil {
          self.activeRangeStart = mark
        }
      }
      markReturnedSectionEnded = { mark in self.activeRangeEnd = mark }
      hasReturnedSectionBegan = { self.activeRangeStart != nil }
    }
    
    var lastValidItemIndexPath : NSIndexPath?
    
    var itemIndexPath : NSIndexPath! = startIndexPath
    var currentY = currentY
    
    // Loop through index paths while available
    
    while itemIndexPath != nil {
      
      if flowLine.active {
        
        let cellAttrs = cellAttributes[itemIndexPath]
        
        if cellAttrs == nil || cellAttrs?.placement != .Flow {
          
          let lineFrame = flowLine.layoutLineAt(&currentY)
          
          if rect.intersects(lineFrame) {

            let linesLayoutAttrs = flowLine.generatedLayoutAttributes!
            
            result.appendContentsOf(linesLayoutAttrs as [UICollectionViewLayoutAttributes])
            
            // Track index paths
            lastValidItemIndexPath = linesLayoutAttrs.last!.indexPath
            markReturnedSectionBegan(linesLayoutAttrs.first!.indexPath)
          }
          
          continue
        }
        else {
          
          flowLine.addItemAtIndexPath(itemIndexPath, withAttributes: cellAttrs!)
          
        }
        
        itemIndexPath = advanceIndexPath(itemIndexPath)
        continue
      }
      
      
      // Find, or estimate, cell attributes
      
      let itemHeightWithMargins : CGFloat
      
      let foundCellAttrs : CellAttributes?
      if let cellAttrs = cellAttributes[itemIndexPath] {
        
        foundCellAttrs = cellAttrs
        itemHeightWithMargins = cellAttrs.totalHeight

        // Start flowing
        if cellAttrs.placement == .Flow {
          flowLine.active = true
          continue
        }
        
      }
      else {
        foundCellAttrs = nil
        itemHeightWithMargins = estimatedCellSize.height + cellMargins.totalVertical
      }
      
      
      currentY += advanceYPre(itemHeightWithMargins)
      
      let itemFrameWithMargins = CGRect(x: 0, y: currentY, width: collectionView!.frame.size.width, height: itemHeightWithMargins)
      
      currentY += advanceYPost(itemHeightWithMargins)
      
      
      // Next, based on estimates check if we should include item's attributes
      
      if rect.intersects(itemFrameWithMargins) {
        
        let cellAttrs : CellAttributes
        if let found = foundCellAttrs {
          cellAttrs = found
    
          // TODO: find source of this
          if cellAttrs.yPosition != itemFrameWithMargins.minY {
            print("whoa")
          }
          
          cellAttrs.yPosition = itemFrameWithMargins.minY
        }
        else {
          cellAttrs = generateCellAttributesForItemAtIndexPath(itemIndexPath, at: itemFrameWithMargins.minY)
        }
        
        // Add layout attributes for item
        let layoutAttrs = generateLayoutAttributesForItemAtIndexPath(itemIndexPath, withCellAttributes: cellAttrs)
        result.append(layoutAttrs)
        
        // Add ornament attributes for item
        result.appendContentsOf(generateAllOrnamentLayoutAttributesForItemAtIndexPath(itemIndexPath, withFrame: layoutAttrs.frame, attrs: cellAttrs))
        
        // Track index paths
        lastValidItemIndexPath = itemIndexPath
        markReturnedSectionBegan(itemIndexPath)
      }
      else if hasReturnedSectionBegan() {
        
        // Layout is done in consecutive sections only. When we hit
        // a non-intersecting frame after we've already found some
        // items, that is our cue to exit the loop.
        
        break
      }
      
      itemIndexPath =  advanceIndexPath(itemIndexPath)
    }
    
    if let last = lastValidItemIndexPath {
      markReturnedSectionEnded(last)
    }
    
    return result
  }
  
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    
    let attrs : UICollectionViewLayoutAttributes
    
    if let cellAttrs = cellAttributes[indexPath] {
      
      attrs = generateLayoutAttributesForItemAtIndexPath(indexPath, withCellAttributes: cellAttrs)
    }
    else {
      
      let index = absoluteIndexFromIndexPath(indexPath)
      let estimatedY = CGFloat(index) * (estimatedCellSize.height + cellMargins.totalVertical)
      
      let cellAttrs = generateCellAttributesForItemAtIndexPath(indexPath, at: estimatedY)
      attrs = generateLayoutAttributesForItemAtIndexPath(indexPath, withCellAttributes: cellAttrs)
    }
    
    return attrs
  }
  
  override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    
    if let ornament = MessagesViewCellOrnament(rawValue: elementKind) {
      
      guard let cellAttrs = cellAttributes[indexPath] else {
        fatalError("cannot generated supplementary view attributes without cell attributes")
      }
      
      let cellFrame = calculateFrameForItemWithCellAttributes(cellAttrs)
      
      let attrs : UICollectionViewLayoutAttributes
      
      switch ornament {
      case .ActionMenu:
        attrs = generateActionMenuLayoutAttributesForItemAtIndexPath(indexPath, withFrame: cellFrame, attrs: cellAttrs)
      case .Clarify:
        attrs = generateClarifyLayoutAttributesForItemAtIndexPath(indexPath, withFrame: cellFrame, attrs: cellAttrs)
      case .SenderHeader:
        attrs = generateSenderHeaderLayoutAttributesForItemAtIndexPath(indexPath, withFrame: cellFrame, attrs: cellAttrs)
      case .TimeHeader:
        attrs = generateTimeHeaderLayoutAttributesForItemAtIndexPath(indexPath, withFrame: cellFrame, attrs: cellAttrs)
      case .StatusFooter:
        attrs = generateStatusFooterLayoutAttributesForItemAtIndexPath(indexPath, withFrame: cellFrame, attrs: cellAttrs)
      default:
        fatalError("Unsupported kind of supplementary view")
      }
      
      attrs.hidden = !(cellAttrs.ornaments?.contains(ornament) ?? false)
      
      return attrs
    }
    
    return nil
  }
  
  override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
    
    if newBounds.size != collectionView!.frame.size {
      return true
    }
    
    return false
  }
  
  override func shouldInvalidateLayoutForPreferredLayoutAttributes(prefs: UICollectionViewLayoutAttributes, withOriginalAttributes orig: UICollectionViewLayoutAttributes) -> Bool {
    
    switch orig.representedElementCategory {
    case .Cell:
      let orig = orig as! MessagesViewLayoutAttributes
      let prefs = prefs as! MessagesViewLayoutAttributes
      
      return
        orig.size != prefs.size ||
        orig.alignmentRectInsets != prefs.alignmentRectInsets ||
        orig.placement == nil || orig.placement != prefs.placement ||
        orig.ornaments == nil || orig.ornaments != prefs.ornaments
      
    case .SupplementaryView:
      return
        orig.frame != prefs.frame
      
    case .DecorationView:
      return false
    }
    
  }
  
  override func invalidationContextForPreferredLayoutAttributes(preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
    
    let invalidator = MessagesViewLayoutInvalidator()
    
    switch preferredAttributes.representedElementCategory {
    case .Cell:
      
      guard let cellAttrs = cellAttributes[preferredAttributes.indexPath] else {
        fatalError("missing cell attributes")
      }
      
      updateCellAttributes(cellAttrs, withPreferredAttributes: preferredAttributes as! MessagesViewLayoutAttributes)
      
      refreshCellAttributes(cellAttrs, forItemAtIndexPath: originalAttributes.indexPath)
      
      calculateInvalidationContext(invalidator,
        forCellAttributes: cellAttrs,
        originalAttributes: originalAttributes as! MessagesViewLayoutAttributes)
      
    case .SupplementaryView:
      
      if let
        kind = originalAttributes.representedElementKind,
        ornament = MessagesViewCellOrnament(rawValue: kind),
        ornamentAttrs = ornamentAttributes[ornament]?[preferredAttributes.indexPath] {
          
          updateOrnamentAttributes(ornamentAttrs, withPreferredAttributes: preferredAttributes)
          
          calculateInvalidationContext(invalidator,
            forOrnament: ornament,
            withAttributes: ornamentAttrs,
            originalAttributes: originalAttributes)
          
      }
      
    case .DecorationView:
      break
    }
    
    // TODO: do we need this still?
    //invalidator.relayout = true
    
    let invalidationContext = super.invalidationContextForPreferredLayoutAttributes(preferredAttributes, withOriginalAttributes: originalAttributes) as! MessagesViewLayoutInvalidationContext
    
    return invalidator.commit(invalidationContext)
  }
  
  private func calculateInvalidationContext(invalidator: MessagesViewLayoutInvalidator, forCellAttributes cellAttrs: CellAttributes, originalAttributes attrs: MessagesViewLayoutAttributes) {
    
    let indexPath = attrs.indexPath
    
    invalidator.invalidateItemAtIndexPath(indexPath)
    
    cellAttrs.ornaments?.forEach{ invalidator.invalidateOrnament($0, atIndexPath: indexPath) }
    
    var heightDiff = CGFloat(0)
    let updateStartIndexPath : NSIndexPath?
    
    if cellAttrs.placement! == .Flow {
      
      (heightDiff, updateStartIndexPath) =
        reflowLineAroundCellsAtIndexPath(indexPath, withCellAttributes: cellAttrs, originalAttributes: attrs)
      
    }
    else {
      
      heightDiff = cellAttrs.size.height - attrs.size.height
      updateStartIndexPath = nextIndexPath(indexPath)
      
      
      if cellAttrs.ornaments != attrs.ornaments {
        heightDiff += cellAttrs.margins.totalVertical - attrs.margins.totalVertical
      }
      
    }
    
    if heightDiff != 0 {
      
      invalidator.relayout = true
      
      invalidator.contentSizeAdjustment = CGSize(width: 0, height: heightDiff)
      
      if checkIfOffsetAdjustRequiredWithMinY(cellAttrs.minY, maxY: cellAttrs.maxY) {
        invalidator.contentOffsetAdjustment = CGPoint(x: 0, y: heightDiff)
      }
      
      if let updateStartIndexPath = updateStartIndexPath {
        updateActiveRangeItemsAtIndexPath(updateStartIndexPath, invalidator: invalidator)
      }
      
    }
    
  }
  
  private func calculateInvalidationContext(invalidator: MessagesViewLayoutInvalidator, forOrnament ornament: MessagesViewCellOrnament, withAttributes ornamentAttrs: OrnamentAttributes, originalAttributes attrs: UICollectionViewLayoutAttributes) {
    
    let indexPath = attrs.indexPath
    
    invalidator.invalidateOrnament(ornament, atIndexPath: indexPath)
    
    switch ornament {
    case .TimeHeader, .SenderHeader:
      
      if let cellAttrs = cellAttributes[indexPath] {
        recalculateDependenciesForCellAttributes(cellAttrs, forItemAtIndexPath: indexPath)
      }
      
      fallthrough
      
    case .StatusFooter:

      let heightDiff = ornamentAttrs.size.height - attrs.size.height

      if heightDiff != 0 {
        
        invalidator.relayout = true
        
        invalidator.contentSizeAdjustment = CGSize(width: 0, height: heightDiff)
        
        if checkIfOffsetAdjustRequiredWithMinY(attrs.frame.minY, maxY: attrs.frame.maxY + heightDiff) {
          invalidator.contentOffsetAdjustment = CGPoint(x: 0, y: heightDiff)
        }
      
        if let updateStartIndexPath = nextIndexPath(indexPath) {
          updateActiveRangeItemsAtIndexPath(updateStartIndexPath, invalidator: invalidator)
        }
        
      }
      
    default:break
    }
  }
  
  private func generateCellAttributesForItemAtIndexPath(indexPath: NSIndexPath, at yPosition: CGFloat) -> CellAttributes {
    
    let attrs = CellAttributes(yPosition: yPosition, size: CGSize(width: collectionView!.frame.width, height: estimatedCellSize.height), margins: cellMargins)
    cellAttributes[indexPath] = attrs
    return attrs
  }
  
  private func generateLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withCellAttributes cellAttrs: CellAttributes) -> MessagesViewLayoutAttributes {
    
    // Build new attributes
    let layoutAttrs = MessagesViewLayoutAttributes(forCellWithIndexPath: indexPath)
    
    layoutAttrs.placement = cellAttrs.placement
    layoutAttrs.margins = cellAttrs.margins
    layoutAttrs.ornaments = cellAttrs.ornaments
    layoutAttrs.alignmentRectInsets = cellAttrs.alignmentRectInsets
    layoutAttrs.frame = calculateFrameForItemWithCellAttributes(cellAttrs)
    
    return layoutAttrs
  }
  
  private func updateCellAttributes(cellAttrs: CellAttributes, withPreferredAttributes preferredAttrs: MessagesViewLayoutAttributes) {
    
    cellAttrs.size = preferredAttrs.size
    cellAttrs.alignmentRectInsets = preferredAttrs.alignmentRectInsets
    
    recalculateDependenciesForCellAttributes(cellAttrs, forItemAtIndexPath: preferredAttrs.indexPath)
  }
  
  private func refreshCellAttributes(cellAttrs: CellAttributes, forItemAtIndexPath indexPath: NSIndexPath) {
    
    refreshCellAttributes(cellAttrs, fromDelegateForItemAtIndexPath: indexPath)
    
    recalculateDependenciesForCellAttributes(cellAttrs, forItemAtIndexPath: indexPath)
  }
  
  private func refreshCellAttributes(cellAttrs: CellAttributes, fromDelegateForItemAtIndexPath indexPath: NSIndexPath, forced: Bool = false) {
    
    if cellAttrs.placement == nil || forced {
      cellAttrs.placement = delegate!.collectionView(collectionView!, messagesLayout: self, placementForItemAtIndexPath: indexPath)
    }
    
    if cellAttrs.ornaments == nil || forced {
      cellAttrs.ornaments = delegate!.collectionView(collectionView!, messagesLayout: self, ornamentsForItemAtIndexPath: indexPath)
    }
    
  }
  
  private func recalculateDependenciesForCellAttributes(cellAttrs: CellAttributes, forItemAtIndexPath indexPath: NSIndexPath) {
    
    cellAttrs.margins = calculateMarginsForItemAtIndexPath(indexPath, withCellAttributes: cellAttrs)
  }
  
  private func calculateMarginsForItemAtIndexPath(indexPath: NSIndexPath, withCellAttributes attrs: CellAttributes) -> UIEdgeInsets {
    
    // Start with default margins
    var margins = cellMargins
    
    if let ornaments = attrs.ornaments {
      
      if ornaments.contains(.TimeHeader) {
        let ornamentAttrsSize = ornamentAttributes[.TimeHeader]?[indexPath]?.size ?? estimatedTimeHeaderSize
        margins.top += ornamentAttrsSize.height
      }
      
      if ornaments.contains(.SenderHeader) {
        let ornamentAttrsSize = ornamentAttributes[.SenderHeader]?[indexPath]?.size ?? estimatedSenderHeaderSize
        margins.top += ornamentAttrsSize.height
      }
      
      if ornaments.contains(.StatusFooter) {
        let ornamentAttrsSize = ornamentAttributes[.StatusFooter]?[indexPath]?.size ?? estimatedStatusFooterSize
        margins.bottom += ornamentAttrsSize.height
      }
      
      if ornaments.contains(.ActionMenu) {
        let ornamentAttrsSize = ornamentAttributes[.ActionMenu]?[indexPath]?.size ?? estimatedActionMenuSize
        let placement = attrs.placement ?? .RightAlign
        if placement == .LeftAlign {
          margins.left = ornamentAttrsSize.width
        }
        else if placement == .RightAlign {
          margins.right = ornamentAttrsSize.width
        }
      }
      
    }
    
    if let dragDistance = attrs.actionMenuDragDistance {
      
      let dragOffset = attrs.actionMenuDragOffset ?? 0
      
      let actionMenuWidth = ornamentAttributes[.ActionMenu]?[indexPath]?.size.width ?? estimatedActionMenuSize.width
        
      switch attrs.placement! {
      case .LeftAlign:
        margins.left += max(dragOffset + dragDistance, cellMargins.left) - actionMenuWidth
        
      case .RightAlign:
        margins.right += max(dragOffset + dragDistance, cellMargins.right) - actionMenuWidth
        
      case .Flow:
        fatalError("Cannot drag flow item")
      }
    }
    
    return margins
  }
  
  private func calculateFrameForItemWithCellAttributes(attrs: CellAttributes) -> CGRect {
    
    let frameY = attrs.yPosition + attrs.margins.top
    
    switch attrs.placement ?? .RightAlign {
      
    case .Flow:
      return CGRect(origin: CGPoint(x: 0, y: frameY), size: attrs.size)
      
    case .LeftAlign:
      let xOff = attrs.margins.left
      return CGRect(origin: CGPoint(x: xOff, y: frameY), size: attrs.size)
      
    case .RightAlign:
      let xOff = collectionView!.frame.width - (attrs.size.width + attrs.margins.right)
      return CGRect(origin: CGPoint(x: xOff, y: frameY), size: attrs.size)
      
    }
    
  }
  
  private func generateAllOrnamentLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> [UICollectionViewLayoutAttributes] {
    
    var ornamentAttrs = [UICollectionViewLayoutAttributes]()
    
    if let ornaments = attrs.ornaments {
      
      if ornaments.contains(.TimeHeader) {
        
        let headerAttrs = generateTimeHeaderLayoutAttributesForItemAtIndexPath(indexPath, withFrame: frame, attrs: attrs)
        
        ornamentAttrs.append(headerAttrs)
      }
      
      if ornaments.contains(.SenderHeader) {
        
        let headerAttrs = generateSenderHeaderLayoutAttributesForItemAtIndexPath(indexPath, withFrame: frame, attrs: attrs)
        
        ornamentAttrs.append(headerAttrs)
      }
      
      if ornaments.contains(.Clarify) {
        
        let iconAttrs = generateClarifyLayoutAttributesForItemAtIndexPath(indexPath, withFrame: frame, attrs: attrs)
        
        ornamentAttrs.append(iconAttrs)
      }
      
      if ornaments.contains(.ActionMenu) {
        
        let menuAttrs = generateActionMenuLayoutAttributesForItemAtIndexPath(indexPath, withFrame: frame, attrs: attrs)
        
        ornamentAttrs.append(menuAttrs)
      }
      
      if ornaments.contains(.StatusFooter) {
        
        let footerAttrs = generateStatusFooterLayoutAttributesForItemAtIndexPath(indexPath, withFrame: frame, attrs: attrs)
        
        ornamentAttrs.append(footerAttrs)
      }
      
    }
    
    return ornamentAttrs
  }
  
  private func findOrGenerateOrnamentAttributesForOrnament(ornament: MessagesViewCellOrnament, atIndexPath indexPath: NSIndexPath, withEstimatedSize estimatedCellSize: CGSize) -> OrnamentAttributes {
    
    if let found = ornamentAttributes[ornament]?[indexPath] {
      return found
    }
    else {
      let attrs = OrnamentAttributes(size: estimatedCellSize)
      ornamentAttributes[ornament]?[indexPath] = attrs
      return attrs
    }
  }
  
  private func generateTimeHeaderLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> UICollectionViewLayoutAttributes {
    
    let ornamentAttrs = findOrGenerateOrnamentAttributesForOrnament(.TimeHeader, atIndexPath: indexPath, withEstimatedSize: estimatedTimeHeaderSize)
    let layoutAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MessagesViewCellOrnament.TimeHeader.rawValue, withIndexPath: indexPath)
    
    layoutAttrs.size = ornamentAttrs.size
    layoutAttrs.position = CGPoint(x: (collectionView!.frame.width - ornamentAttrs.size.width)/2.0, y: frame.minY - attrs.margins.top)
    
    return layoutAttrs
  }
  
  private func generateSenderHeaderLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> UICollectionViewLayoutAttributes {
    
    let frame = frame.inset(attrs.alignmentRectInsets ?? UIEdgeInsets())
    let ornamentAttrs = findOrGenerateOrnamentAttributesForOrnament(.SenderHeader, atIndexPath: indexPath, withEstimatedSize: estimatedSenderHeaderSize)
    let layoutAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MessagesViewCellOrnament.SenderHeader.rawValue, withIndexPath: indexPath)
    
    layoutAttrs.frame = CGRect(origin: CGPoint(x: cellMargins.left, y: frame.minY - ornamentAttrs.size.height), size: ornamentAttrs.size)
    
    return layoutAttrs
  }
  
  private func generateClarifyLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> UICollectionViewLayoutAttributes {
    
    let frame = frame.inset(attrs.alignmentRectInsets ?? UIEdgeInsets())
    let ornamentAttrs = findOrGenerateOrnamentAttributesForOrnament(.Clarify, atIndexPath: indexPath, withEstimatedSize: estimatedClarifyIconSize)
    let layoutAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MessagesViewCellOrnament.Clarify.rawValue, withIndexPath: indexPath)
    
    let xOrigin : CGFloat
    switch attrs.placement ?? .RightAlign {
    case .LeftAlign:
      xOrigin = frame.maxX + attrs.margins.right + ornamentAttrs.size.halfWidth
      
    case .RightAlign:
      xOrigin = frame.minX - attrs.margins.left - ornamentAttrs.size.halfWidth
      
    case .Flow:
      fatalError("invalid cell placement for action menu, must be left or rigth aligned")
    }
    
    layoutAttrs.size = ornamentAttrs.size
    layoutAttrs.center = CGPoint(x: xOrigin, y: frame.midY)
    
    return layoutAttrs
  }
  
  private func generateActionMenuLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> UICollectionViewLayoutAttributes {
    
    let frame = frame.inset(attrs.alignmentRectInsets ?? UIEdgeInsets())
    let ornamentAttrs = findOrGenerateOrnamentAttributesForOrnament(.ActionMenu, atIndexPath: indexPath, withEstimatedSize: estimatedActionMenuSize)
    let layoutAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MessagesViewCellOrnament.ActionMenu.rawValue, withIndexPath: indexPath)
    
    switch attrs.placement ?? .RightAlign {
    case .LeftAlign:
      let xMin = min(frame.minX - ornamentAttrs.size.width, 0)
      let width = max(frame.minX, ornamentAttrs.size.width)
      layoutAttrs.frame = CGRect(origin: CGPoint(x: xMin, y: frame.midY - ornamentAttrs.size.halfHeight), size: CGSize(width: width, height: ornamentAttrs.size.height))
      
    case .RightAlign:
      let xMax = max(frame.maxX + ornamentAttrs.size.width, collectionView!.frame.width)
      let width = max(collectionView!.frame.width - frame.maxX, ornamentAttrs.size.width)
      layoutAttrs.frame = CGRect(origin: CGPoint(x: xMax - width, y: frame.midY - ornamentAttrs.size.halfHeight), size: CGSize(width: width, height: ornamentAttrs.size.height))
      
    case .Flow:
      fatalError("invalid cell placement for action menu, must be left or rigth aligned")
    }
    
    
    return layoutAttrs
  }
  
  private func generateStatusFooterLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, withFrame frame: CGRect, attrs: CellAttributes) -> UICollectionViewLayoutAttributes {
    
    let ornamentAttrs = findOrGenerateOrnamentAttributesForOrnament(.StatusFooter, atIndexPath: indexPath, withEstimatedSize: estimatedStatusFooterSize)
    let layoutAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MessagesViewCellOrnament.StatusFooter.rawValue, withIndexPath: indexPath)
    
    let quoteSpace = attrs.ornaments?.contains(.Quote) ?? false ? attrs.alignmentRectInsets?.totalVertical ?? 0 : 0
    
    layoutAttrs.size = ornamentAttrs.size
    layoutAttrs.position = CGPoint(x: collectionView!.frame.maxX - ornamentAttrs.size.width - cellMargins.right, y: frame.maxY + quoteSpace)
    
    return layoutAttrs
  }
  
  private func updateOrnamentAttributes(ornamentAttrs: OrnamentAttributes, withPreferredAttributes preferredAttrs: UICollectionViewLayoutAttributes) {
    
    ornamentAttrs.size = preferredAttrs.size
  }
  
  private func updateActiveRangeItemsAtIndexPath( startIndexPath: NSIndexPath, invalidator: MessagesViewLayoutInvalidator) {
    
    var startIndexPath = startIndexPath
    
    if startIndexPath.section > activeRangeEnd?.section || (startIndexPath.section == activeRangeEnd?.section && startIndexPath.item > activeRangeEnd?.item) {
      // Past range, ignore
      return
    }
    else if startIndexPath.section < activeRangeStart?.section || (startIndexPath.section == activeRangeStart?.section && startIndexPath.item < activeRangeStart?.item) {
      // Prior to range, start at beginning
      startIndexPath = activeRangeStart!
    }
    
    let end = nextIndexPath(activeRangeEnd!)
    
    let adjustmentHeight = invalidator.contentSizeAdjustment.height
    
    var indexPath : NSIndexPath! = startIndexPath
    
    while indexPath != end {
      
      if let attrs = cellAttributes[indexPath] {
        
        attrs.yPosition += adjustmentHeight
        
        invalidator.invalidateItemAtIndexPath(indexPath)
        
        attrs.ornaments?.forEach{ invalidator.invalidateOrnament($0, atIndexPath: indexPath) }
        
      }
      else {
        break
      }
      
      indexPath = nextIndexPath(indexPath)
    }
    
  }
  
  private func reflowLineAroundCellsAtIndexPath(indexPath: NSIndexPath, withCellAttributes cellAttrs: CellAttributes, originalAttributes attrs: MessagesViewLayoutAttributes) -> (CGFloat, NSIndexPath?) {
    
    // Find starting cell
    var startIndexPath : NSIndexPath! = indexPath
    while startIndexPath != nil {
      if let prev = previousIndexPath(startIndexPath) {
        if cellAttributes[prev]?.placement != .Flow {
          break
        }
        else {
          startIndexPath = prev
        }
      }
      else {
        break
      }
    }
    
    // Find past last cell
    var endIndexPath : NSIndexPath! = nextIndexPath(indexPath)
    while endIndexPath != nil {
      if cellAttributes[endIndexPath]?.placement != .Flow {
        break
      }
      endIndexPath = nextIndexPath(endIndexPath)
    }
    
    var flowLine = MessagesViewLayoutFlowLine(maxWidth: collectionView!.frame.width, direction: .Forward, generateLayoutAttributes: false)

    var accumulatedLineHeight = CGFloat(0)
    var curIndexPath = startIndexPath
    while curIndexPath != endIndexPath {
      let cellAttrs = cellAttributes[curIndexPath]!
      accumulatedLineHeight += cellAttrs.lineHeight ?? attrs.size.height
      flowLine.addItemAtIndexPath(curIndexPath, withAttributes: cellAttrs)
      curIndexPath = nextIndexPath(curIndexPath)
    }
    
    var currentY = cellAttrs.yPosition
    
    let linesRect = flowLine.layoutLineAt(&currentY)
    
    return (linesRect.height - accumulatedLineHeight, startIndexPath)
  }
  
  private func nextIndexPath(indexPath: NSIndexPath) -> NSIndexPath? {
    
    var section = indexPath.section
    var item = indexPath.item + 1
    
    while section < sectionItemCounts.count && item == sectionItemCounts[section] {
      section += 1
      item = 0
    }
    
    if section == sectionItemCounts.count {
      return nil
    }
    
    return NSIndexPath(forItem: item, inSection: section)
  }
  
  private func previousIndexPath(indexPath: NSIndexPath) -> NSIndexPath? {
    
    var section = indexPath.section
    var item = indexPath.item - 1
    
    while item <= -1 && section > 0 {
      section -= 1
      item = sectionItemCounts[section] - 1
    }
    
    if item == -1 {
      return nil
    }
    
    return NSIndexPath(forItem: item, inSection: section)
  }
  
  private func indexPathFromAbsoluteIndex(index: Int) -> NSIndexPath {
    
    var index = index
    
    for section in 0 ..< sectionItemCounts.count {
      let newIndex = index - sectionItemCounts[section]
      if newIndex < 0 {
        return NSIndexPath(forItem: index, inSection: section)
      }
      index = newIndex
    }
    
    fatalError("invalid index")
  }
  
  private func absoluteIndexFromIndexPath(indexPath: NSIndexPath) -> Int {
    
    var index = 0
    
    for section in 0..<indexPath.section {
      index += sectionItemCounts[section]
    }
    
    return index + indexPath.item
  }
  
  private func checkIfOffsetAdjustRequiredWithMinY(minY: CGFloat, maxY: CGFloat) -> Bool {
    let bounds = collectionView!.bounds
    return minY < bounds.minY && maxY < bounds.maxY
  }
  
}



private struct MessagesViewLayoutFlowLine {
  
  let maxWidth : CGFloat
  let direction : MessagesViewLayout.Direction
  var items : [(NSIndexPath,MessagesViewLayout.CellAttributes)] = []
  var active = false
  var generateLayoutAttributes : Bool
  var generatedLayoutAttributes : [MessagesViewLayoutAttributes]?
  
  init(maxWidth: CGFloat, direction: MessagesViewLayout.Direction, generateLayoutAttributes: Bool = true) {
    self.maxWidth = maxWidth
    self.direction = direction
    self.generateLayoutAttributes = generateLayoutAttributes
  }
  
  mutating func addItemAtIndexPath(indexPath: NSIndexPath, withAttributes attrs: MessagesViewLayout.CellAttributes) {
    
    switch direction {
    case .Forward:
      items.append((indexPath,attrs))
      
    case .Backward:
      items.insert((indexPath,attrs), atIndex: 0)
      
    }
    
  }
  
  
  class Line {
    var items : [(NSIndexPath,MessagesViewLayout.CellAttributes)] = []
    var size = CGSize()
  }
  
  mutating func layoutLineAt(inout currentY: CGFloat) -> CGRect {

    var lines = [Line()]
    
    if generateLayoutAttributes {
      generatedLayoutAttributes = [MessagesViewLayoutAttributes]()
    }

    // Sort onto lines based on width
    
    for (indexPath,item) in items {
      
      if lines.last!.size.width + item.size.width + item.margins.totalHorizontal > maxWidth {
        lines.append(Line())
      }
      
      let line = lines.last!
      
      line.items.append((indexPath,item))
      line.size.width += item.size.width + item.margins.totalHorizontal
      line.size.height = max(line.size.height, item.size.height + item.margins.totalVertical)
    }
    
    // Calculate final frames
    
    var totalSize = CGSize()

    if direction == .Backward {
      lines = lines.reverse()
    }
    
    for line in lines {
      
      if direction == .Backward {
        currentY -= line.size.height
      }
      
      var currentX = CGFloat(0)
      
      for (indexPath,item) in line.items {
        
        currentX += item.margins.left

        item.yPosition = currentY + item.margins.top
        item.lineHeight = 0
        
        if generateLayoutAttributes {
          let layoutAttrs = MessagesViewLayoutAttributes(forCellWithIndexPath: indexPath)
          layoutAttrs.placement = .Flow
          layoutAttrs.margins = item.margins
          layoutAttrs.alignmentRectInsets = item.alignmentRectInsets
          layoutAttrs.frame = CGRect(x: currentX, y: item.yPosition, width: item.size.width, height: item.size.height)
          generatedLayoutAttributes!.append(layoutAttrs)
        }
        
        currentX += item.size.width + item.margins.right
        
      }
      
      // Last cell in the line gets the line height
      line.items.last?.1.lineHeight = line.size.height
      
      if direction == .Forward {
        currentY += line.size.height
      }
      
      totalSize.width = max(totalSize.width, line.size.width)
      totalSize.height += line.size.height
    }
    
    items.removeAll(keepCapacity: true)
    active = false
    
    if direction == .Forward {
      return CGRect(origin: CGPoint(x: 0, y: currentY - totalSize.height), size: totalSize)
    }
    else {
      return CGRect(origin: CGPoint(x: 0, y: currentY), size: totalSize)
    }
  }
  
}



class MessagesViewLayoutInvalidator {
  
  private var contentOffsetAdjustment = CGPoint()
  private var contentSizeAdjustment = CGSize()
  private var items = Set<NSIndexPath>()
  private var ornamentItems = [MessagesViewCellOrnament: Set<NSIndexPath>]()
  
  private var _relayout = false
  var relayout : Bool {
    get {
      return _relayout
    }
    set {
      _relayout = newValue
      items.removeAll()
      ornamentItems.removeAll()
    }
  }
  
  func invalidateItemAtIndexPath(indexPath: NSIndexPath) {
    
    if relayout { return }
    
    items.insert(indexPath)
  }
  
  func invalidateOrnament(ornament: MessagesViewCellOrnament, atIndexPath indexPath: NSIndexPath) {
    
    if relayout || ornament == .Quote { return }
    
    var items = ornamentItems[ornament] ?? []
    items.insert(indexPath)
    ornamentItems[ornament] = items
  }
  
  func commit(context: MessagesViewLayoutInvalidationContext) -> MessagesViewLayoutInvalidationContext {
    
    context.contentOffsetAdjustment += contentOffsetAdjustment
    context.contentSizeAdjustment += contentSizeAdjustment
    
    if relayout {
      return context
    }
    
    context.invalidateItemsAtIndexPaths(Array(items))
    
    for (ornament, items) in ornamentItems {
      context.invalidateSupplementaryElementsOfKind(ornament.rawValue, atIndexPaths: Array(items))
    }
    
    return context
  }
  
}
