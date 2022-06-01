import SwiftUI

var tableViewLocked = false

/// A custom parameter attribute that constructs capsule table columns from closures.
@resultBuilder public struct CapsuleTableColumnBuilder<T> {
//  public static func buildOptional(_ component: [CapsuleTableColumn<T>]?) -> [CapsuleTableColumn<T>] {
//    component
//  }
  // public static func buildBlock() -> [CapsuleTableColumn<T>] { [] }
  public static func buildExpression(_ column: CapsuleTableColumn<T>) -> CapsuleTableColumn<T> { column }
  public static func buildBlock(_ columns: CapsuleTableColumn<T>...) -> [CapsuleTableColumn<T>] { columns }
  public static func buildOptional(_ columns: [CapsuleTableColumn<T>]?) -> [CapsuleTableColumn<T>] { columns ?? [] }
  
//  public static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2)-> CapsuleTupleTableColumnContent<T, (C0, C1, C2)> {
//    .init(value: (c0, c1, c2))
//  }
}

fileprivate var _ImageKey: UInt8 = 0
fileprivate var KeyPathKey: UInt8 = 0
fileprivate var ValueTransformKey: UInt8 = 0
fileprivate var OnSubmitKey: UInt8 = 0
fileprivate var _ActionKey: UInt8 = 0
//fileprivate var ComboDataSourceKey: UInt8 = 0

/// A column that displays a cell for each row in a capsule table.
public final class CapsuleTableColumn<RowValue>: NSTableColumn {
  var _image: ((RowValue) -> NSImage?)? {
    get { objc_getAssociatedObject(self, &_ImageKey) as? (RowValue) -> NSImage? }
    set { objc_setAssociatedObject(self, &_ImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  var keyPath: Any? {
    get { objc_getAssociatedObject(self, &KeyPathKey) }
    set { objc_setAssociatedObject(self, &KeyPathKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
  
  var valueTransform: ((Any, Int) -> Any?)? {
    get { objc_getAssociatedObject(self, &ValueTransformKey) as! ((Any, Int) -> Any?)? }
    set { objc_setAssociatedObject(self, &ValueTransformKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
  
  var onSubmit: ((Int) -> (Any?) -> Void)? {
    get { objc_getAssociatedObject(self, &OnSubmitKey) as! ((Int) -> (Any?) -> Void)? }
    set { objc_setAssociatedObject(self, &OnSubmitKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
  
//  var comboDataSource: NSComboBoxCellDataSource? {
//    get { objc_getAssociatedObject(self, &OnSubmitKey) as! NSComboBoxCellDataSource? }
//    set { objc_setAssociatedObject(self, &OnSubmitKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
//  }
}

extension NSTableColumn {
  var _action: ((Any?) -> Void)? {
    get { objc_getAssociatedObject(self, &_ActionKey) as! ((Any?) -> Void)? }
    set { objc_setAssociatedObject(self, &_ActionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
}

public extension CapsuleTableColumn {
  func withAlignment(_ value: NSTextAlignment) -> Self {
    headerCell.alignment = value
    (dataCell as? NSCell)?.alignment = value
    return self
  }
  
  func withFont(_ value: NSFont) -> Self {
    (dataCell as? NSCell)?.font = value
    return self
  }
  
  func withImage(_ value: @escaping (RowValue) -> NSImage?) -> Self {
    _image = value
    return self
  }

  func withImage(_ value: NSImage?) -> Self {
    withImage { _ in value }
  }
  
  func withToolTip(_ value: String?) -> Self {
    headerToolTip = value
    return self
  }
  
  func withWidth(_ value: CGFloat) -> Self {
    withWidth(min: value, max: value)
  }

  func withWidth(min: CGFloat = 0, ideal: CGFloat = 100, max: CGFloat = .greatestFiniteMagnitude) -> Self {
    minWidth = min
    width = ideal
    maxWidth = max
    return self
  }
}

public extension CapsuleTableColumn {
  convenience init(_ title: String, value keyPath: KeyPath<RowValue, String>, onSubmit: ((Int, String) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath
    if let onSubmit = onSubmit {
      self.onSubmit = { i in { v in onSubmit(i, v as! String) } }
    }
    
    let cell = CapsuleTableLabelCell()
    cell.isEditable = onSubmit != nil
    cell.truncatesLastVisibleLine = true
    // cell.alignment = .right     // cell.cellsize
    // cell.interiorBackgroundStyle = .emphasized
    //cell.cellSize =NSMakeSize(0, 32)
    dataCell = cell
  }

  convenience init(_ title: String, value keyPath: KeyPath<RowValue, NSAttributedString>, onSubmit: ((Int, String) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath
    if let onSubmit = onSubmit {
      self.onSubmit = { i in { v in onSubmit(i, v as! String) } }
    }
    
    let cell = CapsuleTableLabelCell()
    cell.isEditable = onSubmit != nil
    cell.truncatesLastVisibleLine = true
    // cell.alignment = .right     // cell.cellsize
    // cell.interiorBackgroundStyle = .emphasized
    //cell.cellSize =NSMakeSize(0, 32)
    dataCell = cell
  }

  convenience init(_ title: String, value keyPath: KeyPath<RowValue, Bool>, onSubmit: ((Int, Bool) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath
    
    var newValue: Int?
    var overridenRow: Int?
    valueTransform = { v, i in
      if newValue != nil && overridenRow == i {
        defer { newValue = nil; overridenRow = nil }
        return newValue!
      } else {
        return v
      }
    }
    
    if let onSubmit = onSubmit {
      self.onSubmit = { i in { v in
        newValue = (v as! Int)
        onSubmit(i, v as! Bool)
      } }
    }
    
    _action = { tableView in
      guard let tableView = tableView as? NSTableView else { return }
      overridenRow = tableView.clickedRow
    }


    let cell = NSButtonCell()
    cell.title = nil
    cell.setButtonType(.switch)
    cell.imagePosition = .imageOnly
    // cell.controlSize = .small
    cell.action = #selector(NSTableColumn._performAction(_:))
    cell.target = self
    dataCell = cell
  }

  convenience init(_ title: String, value keyPath: KeyPath<RowValue, Date>, onSubmit: ((Int, Date) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath

    let cell = NSDatePickerCell()
    // cell.controlSize = .small
    dataCell = cell
  }

//  convenience init<V>(_ title: String, value keyPath: KeyPath<RowValue, Binding<V>>) {
//    self.init(identifier: NSUserInterfaceItemIdentifier(title))
//    self.title = title
//    self.keyPath = keyPath
//  }
  
//  class ComboDataSource: NSObject, NSComboBoxCellDataSource {
//    var items: [String]
//
//    init(_ items: [String]) { self.items = items }
//
//    public func numberOfItems(in comboBoxCell: NSComboBoxCell) -> Int {
//      items.count
//    }
//
//    public func comboBoxCell(_ comboBoxCell: NSComboBoxCell, objectValueForItemAt index: Int) -> Any {
//      items[index]
//    }
//
//    public func comboBoxCell(_ comboBoxCell: NSComboBoxCell, indexOfItemWithStringValue string: String) -> Int {
//      items.firstIndex(of: string) ?? NSNotFound
//    }
//
//    public func comboBoxCell(_ comboBoxCell: NSComboBoxCell, completedString uncompletedString: String) -> String? {
//      items.first { $0.caseInsensitiveHasPrefix(uncompletedString) }
//    }
//  }

  convenience init(_ title: String, value keyPath: KeyPath<RowValue, String>, completions: [(NSImage, String)], onSubmit: ((Int, String) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath
    let cell = CapsuleTableComboBoxCell()
    // cell.controlSize = .small
    cell.isButtonBordered = false
    // cell.isBordered = false
    // cell.isBezeled = false
    cell.isEditable = onSubmit != nil
//    cell.usesDataSource = true
//    comboDataSource = ComboDataSource(completions)
//    cell.dataSource = comboDataSource
    cell.completes = true
    cell.addItems(withObjectValues: completions)
    cell.numberOfVisibleItems = 20
    // cell.isButtonBordered = false
//    if let tableView = cell.value(forKey: "_tableView") as? NSTableView {
////      tableView.rowHeight = 49
//    }
    dataCell = cell

    var newValue: String?
    var overridenRow: Int?
//    valueTransform = { v, i in
////      if let (_, v) = v as? (NSImage, String) {
////        return v
////      } else {
////        return v
////      }
//      if newValue != nil && overridenRow == i {
//        defer { newValue = nil; overridenRow = nil }
//        return newValue!
//      } else {
//        return v
//      }
//    }
    
    
//    valueTransform = { v, i in
//      return "\(v)".firstCapitalized
//
////      if newValue != nil && overridenRow == i {
////        defer { newValue = nil; overridenRow = nil }
////        return newValue!
////      } else {
////        return V.allCases.enumerated().first(where: { (_, e) in e == v as! V })?.offset
////      }
//    }
  
    if let onSubmit = onSubmit {
      self.onSubmit = { i in { v in
        if let v = v as? String {
          newValue = v
          onSubmit(i, v)
        } else if let (_, v) = v as? (NSImage, String) {
          newValue = v
          onSubmit(i, v)
        }
      } }
    }
    
//    if let onSubmit = onSubmit {
//      self.onSubmit = { i in { v in
//         // onSubmit(i, V.allCases[v as! V.AllCases.Index])
//        // onSubmit(i, V.allCases.first!)
//      } }
//    }
  }
  
  convenience init<V: CaseIterable & Equatable>(_ title: String, value keyPath: KeyPath<RowValue, V>, onSubmit: ((Int, V) -> Void)? = nil) {
    self.init(identifier: NSUserInterfaceItemIdentifier(title))
    self.title = title
    self.keyPath = keyPath

    let cell = CapsuleTablePopUpButtonCell()
    cell.isBordered = false
    cell.isEnabled = onSubmit != nil
    cell.imageDimsWhenDisabled = false
    let menu = NSMenu()
    menu.items = V.allCases.enumerated().map { (offset, element) in
      let item = NSMenuItem(title: "\(element)".firstCapitalized, action: nil, keyEquivalent: "")
      item.tag = offset
      return item
    }
    cell.menu = menu
    cell.action = #selector(NSTableColumn._performAction(_:))
    cell.target = self
//    cell.sendsActionOnEndEditing = true
//    cell.select(cell.menu?.items.first)
//    var newValue: Int?
//    var overridenRow: Int?
    // var valueOverrideRow
    valueTransform = { v, i in
//      if newValue != nil && overridenRow == i {
//        defer { newValue = nil; overridenRow = nil }
//        return newValue!
//      } else {
        return V.allCases.enumerated().first(where: { (_, e) in e == v as! V })?.offset
//      }
    }
    // cell.controlSize = .small
    dataCell = cell
    
//    _action = { tableView in
//      guard let tableView = tableView as? NSTableView else { return }
//
//      overridenRow = tableView.clickedRow
////      tableViewLocked = true
//////      DispatchQueue.main.async {
//////        NSApp.runModal(for: (tableView as! NSView).window!)
//////      }
//////      tableView.lock()
//////      tableView.unlock()
//////      tableViewLocked = true
//////      (tableView as? NSTableView)?.dataSource = nil
////      NSLog("action")
////      // NSApp.stop(nil)
//    }

    if let onSubmit = onSubmit {
      self.onSubmit = { i in { v in
        NSLog("submit")
        // NSApp.run()
//        cell.objectValue = v
        // cell.isBordered.toggle()
        // objectValue = v
        // self.valueTransform = { _ in v }
        // self.objectValue(for: <#T##RowValue#>, row: <#T##Int#>)
//        NSApp.abortModal()
        // NSDisableScreenUpdates()
        NSAnimationContext.runAnimationGroup { _ in
          onSubmit(i, V.allCases[v as! V.AllCases.Index])
        }
//        DispatchQueue.main.async {
//          DispatchQueue.main.async {
//            NSEnableScreenUpdates()
//          }
//        }
//        tableViewLocked = false
//        newValue = v as? Int
        // self.tableView?.setNeedsDisplay(self.tableView!.bounds)
//        DispatchQueue.main.async {
//          newValue
//        }
        
        // self.tableView?.reloadData()
//         self.tableView?.setNeedsDisplay(self.tableView!.bounds)
//        DispatchQueue.main.async {
//          tableViewLocked = false
//          self.tableView?.reloadData()
//        }
        // self.tableView?.reloadData()
//        cell.objectValue = v
        //cell.selectItem(at: v as! Int)
      } }
    }
  }

  //  open override func titleRect(forBounds bounds: NSRect) -> NSRect {
//    var titleFrame = super.titleRect(forBounds: bounds)
//    let titleSize = attributedStringValue.size()
//    titleFrame.origin.y = bounds.origin.y - 1 + (bounds.size.height - titleSize.height) / 2
//    if imageValue != nil {
//      let imageWidth = imageRect(forBounds: bounds).width + 5
//      titleFrame.origin.x += imageWidth
//      titleFrame.size.width -= imageWidth
//    }
//    return titleFrame
//  }
}

extension NSTableColumn {
  @objc func _performAction(_ sender: Any?) {
    _action?(sender)
  }
}

class CapsuleTableComboBoxCell: NSComboBoxCell, NSTableViewDelegate, NSTableViewDataSource {
//  - (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//      [super drawWithFrame:cellFrame inView:controlView];
//

  override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
    var cellFrame = cellFrame
    cellFrame.size.width += 7
    super.draw(withFrame: cellFrame.offsetBy(dx: 0, dy: -2), in: controlView)
//    drawInterior(withFrame: cellFrame, in: controlView)
  }
  
  override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
    super.drawInterior(withFrame: cellFrame.offsetBy(dx: 0, dy: 3.5), in: controlView)
  }
  
  override func completedString(_ string: String) -> String? {
    (0..<numberOfItems)
      .compactMap { itemObjectValue(at: $0) as? (NSImage, String) }
      .map { $0.1 }
      .first { $0.caseInsensitiveHasPrefix(string) }
  }
  
  func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
    CapsuleTableLabelCell()
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    itemObjectValue(at: row)
//    // (NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)!, (itemObjectValue(at: row) as? String ?? ""))
//    (itemObjectValue(at: row) as? (NSImage, String)) ?? (NSImage(), "")
  }
  
//  func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
//    (cell as? CapsuleTableLabelCell)
//  }
  
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    20
  }
  
//  override func titleRect(forBounds rect: NSRect) -> NSRect {
//    super.titleRect(forBounds: rect.insetBy(dx: 0, dy: 5))
//  }
  
  override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
    super.edit(withFrame: rect.insetBy(dx: 5, dy: 5), in: controlView, editor: textObj, delegate: delegate, event: event)
  }

  override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
    super.select(withFrame: rect.insetBy(dx: 0, dy: 3).offsetBy(dx: 0, dy: 2), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
  }

//  override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.drawFocusRingMask(withFrame: cellFrame.insetBy(dx: 0, dy: 5.5).offsetBy(dx: 0, dy: -0.5), in: controlView)
//  }
  
//  override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
//
//  }
  
  override func drawingRect(forBounds rect: NSRect) -> NSRect {
//    super.drawingRect(forBounds: rect.insetBy(dx: -4, dy: 2))
    super.drawingRect(forBounds: rect.insetBy(dx: -4, dy: 0))
  }
  
//  override func hitTest(for event: NSEvent, in cellFrame: NSRect, of controlView: NSView) -> NSCell.HitResult {
//    // guard let tableView = controlView as? NSTableView else { return .contentArea }
//    var location = controlView.convert(event.locationInWindow, from: nil)
//    location.x -= cellFrame.minX
//    location.y -= cellFrame.minY
//    // print(location)
////    return location.y > cellFrame.width - 16 ? .editableTextArea : .trackableArea // TODO: RTL support
//    return .trackableArea
//
//    // if event.locationInWindow
//    // .editableTextArea
//  }
}

class CapsuleTablePopUpButtonCell: NSPopUpButtonCell {
//  override func titleRect(forBounds cellFrame: NSRect) -> NSRect {
//    super.titleRect(forBounds: cellFrame.insetBy(dx: -5, dy: 0))
//  }
  
  override func drawingRect(forBounds rect: NSRect) -> NSRect {
    super.drawingRect(forBounds: rect.insetBy(dx: -2.5, dy: 0))
  }
//
//  override func cellSize(forBounds rect: NSRect) -> NSSize {
//    var s = super.cellSize(forBounds: rect)
//    s.width += 5 * 2
//    return s
//  }
  
//  override func drawSeparatorItem(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.drawSeparatorItem(withFrame: cellFrame, in: controlView)
//  }
//
//  override func drawBorderAndBackground(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.drawBorderAndBackground(withFrame: cellFrame.insetBy(dx: -5, dy: 0), in: controlView)
//  }
  
//  override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.draw(withFrame: cellFrame.insetBy(dx: -5, dy: 0), in: controlView)
//  }
  
//  override func drawBorderAndBackground(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.drawBorderAndBackground(withFrame: cellFrame.insetBy(dx: -5, dy: 0), in: controlView)
//  }
  
//  override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
//    super.drawInterior(withFrame: cellFrame.insetBy(dx: -5, dy: 0), in: controlView)
//  }
}

extension StringProtocol {
  var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

extension String {
  func caseInsensitiveHasPrefix(_ prefix: String) -> Bool {
    range(of: prefix, options: [.anchored, .caseInsensitive]) != nil
  }
}
