//
//  LoopScrollView.swift
//  WordsMarathon
//
//  Created by Vitaliy Podolskiy on 12/11/2018.
//  Copyright © 2018 Vitaliy Podolskiy. All rights reserved.
//

import UIKit

@objc protocol CMLoopScrollViewDelegate : class {
  
  func loopScrollView_numberOfRows(_ scrollView: CMLoopScrollView) -> Int
  func loopScrollView_sizeOfRows(_ scrollView: CMLoopScrollView,row: Int) -> CGSize
  func loopScrollView_cellForRows(_ scrollView: CMLoopScrollView, row: Int) -> CMLoopScrollViewCell
  func loopScrollView_didSelectForRows(_ scrollView: CMLoopScrollView, row: Int)
  
  @objc optional func loopScrollViewDidScroll(_ scrollView: CMLoopScrollView)
  @objc optional func loopScrollViewDidEndDecelerating(_ scrollView: CMLoopScrollView)
  @objc optional func loopScrollView_heightForRows(_ scrollView: CMLoopScrollView, row: Int)
  @objc optional func loopScrollView_unHeightForRows(_ scrollView: CMLoopScrollView, row: Int)
  
}

class CMLoopScrollViewCell: UIView {
  
  var identifier: String = ""
  var isReload = false
  
  weak var parentScrollView : CMLoopScrollView?
  
  func isVisible() -> Bool {
    if let scrollView = self.parentScrollView {
      let offset1 = (self.frame.origin.x + self.frame.size.width) - scrollView.contentOffset.x
      let offset2 = self.frame.origin.x - scrollView.contentOffset.x
      if offset1 > 0 && offset2 < scrollView.frame.size.width {
        return true
      }
    }
    return false
  }
  
}

class CMLoopScrollView: UIScrollView, UIScrollViewDelegate {
  
  weak var loop_delegate : CMLoopScrollViewDelegate?
  var page = 0
  var pageSize: CGFloat = 0
  var cells = [CMLoopScrollViewCell]()
  var rowCount: Int = 0
  
  override func awakeFromNib() {
    self.delegate = self
    self.reloadData()
  }
  
  func reloadData () {
    self.rowCount = self.loop_delegate?.loopScrollView_numberOfRows(self) ?? 0
    self.updateData()
    self.updateLayout()
  }
  
  func updateData () {
    self.pageSize = 0
    for row in 0 ..< self.rowCount {
      let cellSize = self.loop_delegate?.loopScrollView_sizeOfRows(self, row: row) ?? CGSize.zero
      if row < self.cells.count {
        let cell = self.cells[row]
        if cell.isVisible() {
          _ = self.loop_delegate?.loopScrollView_cellForRows(self, row: row)
        }
      }
      else {
        let cell = self.loop_delegate?.loopScrollView_cellForRows(self, row: row)
        cell?.isReload = true
      }
      self.pageSize += cellSize.width
    }
    for row in ((self.rowCount-1) ..< (self.cells.count-1)).reversed() {
      let cell = self.cells[row]
      cell.removeFromSuperview()
      self.cells.remove(at: row)
    }
  }
  
  func updateLayout () {
    _ = self.getCurrentPage()
    var prevCellPosition : CGFloat = 0
    var cellMinOffset : CGFloat = 0
    var cellMaxOffset : CGFloat = 0
    var newScrollContentSize = self.contentSize
    var newScrollContentInset = self.contentInset
    for row in 0 ..< self.cells.count {
      let cellSize = self.loop_delegate?.loopScrollView_sizeOfRows(self, row: row) ?? CGSize.zero
      let cell = self.cells[row]
      cell.parentScrollView = self
      var cframe = cell.frame
      cframe.size = cellSize
      self.contentOffset.y = 0
      let page = Int(self.getScrollOffset().x) / Int(self.pageSize)
      cellMinOffset = -cframe.size.width
      cellMaxOffset = self.frame.size.width
      cframe.origin.x = prevCellPosition + (CGFloat(page) * self.pageSize)
      cframe.origin.y = 0
      if cframe.origin.x - self.getScrollOffset().x < cellMinOffset {
        cframe.origin.x = prevCellPosition + (CGFloat(page+1) * self.pageSize)
      }
      else if cframe.origin.x - self.getScrollOffset().x > cellMaxOffset {
        cframe.origin.x = prevCellPosition + (CGFloat(page-1) * self.pageSize)
      }
      if cframe.origin.x < 0 {
        newScrollContentInset.left = max(abs(cframe.origin.x) + cellSize.width,newScrollContentInset.left)
        newScrollContentInset.top = 0
      }
      else {
        newScrollContentSize.width = max(abs(cframe.origin.x) + (cellSize.width*2),newScrollContentSize.width)
        newScrollContentSize.height = 0
      }
      prevCellPosition += cframe.size.width
      cell.frame = cframe
      if cell.isVisible() {
        if cell.isReload == false {
          _ = self.loop_delegate?.loopScrollView_cellForRows(self, row: row)
          cell.isReload = true
        }
        self.addSubview(cell)
      }
      else {
        cell.isReload = false
        cell.removeFromSuperview()
      }
    }
    self.contentSize  = newScrollContentSize
    self.contentInset = newScrollContentInset
    if self.pageSize <= self.frame.width {
      self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      self.contentSize = CGSize(width: self.frame.width, height: 0)
    }
    else {
      let scrollContent = self.contentInset.left + self.contentSize.width
      if scrollContent < self.pageSize {
        self.contentSize = CGSize(width: self.pageSize, height: 0)
      }
    }
  }
  
  // MARK: - ScrollView Delegate
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.updateLayout()
    self.loop_delegate?.loopScrollViewDidScroll?(self)
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.adjustmentScroll()
    self.loop_delegate?.loopScrollViewDidEndDecelerating?(self)
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    self.adjustmentScroll()
  }
  
  // MARK: - Methods
  
  func getCellWithIdentifier(_ identifier : String, forRow row : Int) -> CMLoopScrollViewCell {
    if row < cells.count {
      let cell = cells[row]
      return cell
    }
    else {
      let cell = CMLoopScrollView.getLayoutFromXib(identifier) as! CMLoopScrollViewCell
      cells.append(cell)
      return cell
    }
  }
  
  func adjustmentScroll () {
    if self.isPagingEnabled == true {
      return
    }
    let row = self.getCurrentRow()
    self.scrollWithRow(row)
  }
  
  func getScrollOffset () -> CGPoint {
    return self.contentOffset
  }
  
  func getCurrentPage () -> Int {
    if self.pageSize == 0 {
      return 0
    }
    if self.getScrollOffset().x + self.frame.size.width / 2 >= 0 {
      self.page = Int(self.getScrollOffset().x + self.frame.size.width / 2) / Int(self.pageSize) + 1
    }
    else {
      self.page = Int(self.getScrollOffset().x + self.frame.size.width / 2) / Int(self.pageSize) - 1
    }
    return self.page
  }
  
  func getPrevRow (_ row : Int) -> Int {
    var newRow = row
    newRow -= 1
    if newRow < 0 {
      newRow = self.rowCount
    }
    return newRow
  }
  
  func getNextRow (_ row : Int) -> Int {
    var newRow = row
    newRow += 1
    if newRow > rowCount {
      newRow = 0
    }
    return newRow
  }
  
  func getCurrentRow () -> Int {
    let row = self.getCurrentRowWithPoint(self.getScrollOffset().x)
    return row
  }
  
  func getCurrentRowWithPoint (_ p : CGFloat) -> Int {
    var point = p
    _ = self.getCurrentPage()
    var currentRow = 0
    point += self.frame.size.width / 2
    for cell in self.cells {
      if cell.frame.contains(CGPoint(x: point, y: self.frame.size.height / 2)) {
        currentRow = self.cells.index(of: cell) ?? 0
        break
      }
    }
    return currentRow
  }
  
  func scrollWithRow (_ row : Int) {
    if self.isDragging == true {
      return
    }
    _ = self.getCurrentPage()
    UIView.animate(withDuration: 0.35, delay: 0.0, options:UIView.AnimationOptions.curveEaseOut, animations: {
      if row < self.cells.count {
        let cell = self.cells[row]
        self.setContentOffset(CGPoint(x: cell.frame.origin.x + cell.frame.size.width / 2 - self.frame.size.width / 2, y: 0), animated: true)
      }
    }, completion: { finished in
    })
  }
  
  //MARK: - Touch Methods
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if let touch =  touches.first {
      let location = touch.location(in: self)
      var row : Int? = nil
      row = self.getCurrentRowWithPoint(location.x - self.frame.size.width / 2)
      if row != nil {
        self.loop_delegate?.loopScrollView_heightForRows?(self, row: row!)
      }
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    if let touch =  touches.first {
      let location = touch.location(in: self)
      var row : Int? = nil
      row = self.getCurrentRowWithPoint(location.x - self.frame.size.width / 2)
      if row != nil {
        self.loop_delegate?.loopScrollView_didSelectForRows(self, row: row!)
      }
    }
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    super.touchesCancelled(touches!, with: event)
    for cell in self.cells {
      let row = self.cells.index(of: cell)
      self.loop_delegate?.loopScrollView_unHeightForRows?(self, row: row!)
    }
  }
  
  static func getLayoutFromXib(_ _xibName:String) -> UIView? {
    let bundle : Bundle = Bundle.main
    var libArray = bundle.loadNibNamed(_xibName, owner: nil, options: nil)
    let _view : UIView = libArray![0] as! UIView
    return _view
  }
  
}
