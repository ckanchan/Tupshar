//
//  ViewController.swift
//  Tupshar: cuneiform text editor
//  Copyright (C) 2018 Chaitanya Kanchan
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import CDKSwiftOracc

class TextViewController: NSViewController, NSTextViewDelegate, OCDLViewDelegate {
    let defaultFormatting = NSFont.systemFont(ofSize: NSFont.systemFontSize).makeDefaultPreferences()
    let cuneiformNA = NSFont(name: "CuneiformNAOutline Medium", size: NSFont.systemFontSize)
    
    @IBOutlet weak var textSelect: NSSegmentedControl!
    @IBOutlet var ocdlView: OCDLView!

    @IBAction func changeText(_ sender: Any) {
        refreshView()
    }

    func refreshView() {
        switch self.textSelect.selectedSegment {
        case 0:
            ocdlView.string = document.text.cuneiform
            ocdlView.font = cuneiformNA
            ocdlView.isEditable = false
            ocdlView.isSelectable = false
            ocdlView.backgroundColor = NSColor.windowBackgroundColor
        case 1:
            ocdlView.textStorage?.setAttributedString(document.text.transliterated().render(withPreferences: defaultFormatting))
            ocdlView.isEditable = false
            ocdlView.isSelectable = false
            ocdlView.backgroundColor = NSColor.windowBackgroundColor
        case 2:
            ocdlView.textStorage?.setAttributedString(document.text.normalised().render(withPreferences: defaultFormatting))
            ocdlView.isEditable = true
            ocdlView.isSelectable = true
            ocdlView.backgroundColor = NSColor.textBackgroundColor
            ocdlView.selectionGranularity = NSSelectionGranularity.selectByWord
            if ocdlView.isContinuousSpellCheckingEnabled {
                ocdlView.toggleContinuousSpellChecking(self)
            }
        case 3:
            ocdlView.string = document.text.literalTranslation
            ocdlView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ocdlView.isEditable = false
            ocdlView.isSelectable = false
            ocdlView.backgroundColor = NSColor.windowBackgroundColor
        default:
            break
        }
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        let textBox = notification.object! as! NSTextView
        guard textBox == self.ocdlView else {return}
        
        let range = textBox.selectedRange()
        if range.location == NSNotFound {
            document.selectedNode = .none
            return
        }
        
        if range.length > 0 {
            registerSelection(in: textBox, at: range)
        } else {
            registerInsertionPoint(in: textBox, at: range)
        }
    }
    
    func registerSelection(in textBox: NSTextView, at range: NSRange) {
        guard let (line, position) = getPathComponents(in: textBox, at: range) else {
            document.selectedNode = .none
            return
        }
        
        document.currentLine = line
        document.selectedNode = .selection(position: position)
    }
    
    func registerInsertionPoint(in textBox: NSTextView, at range: NSRange) {
        // If caret is at the end of the string then return.
        guard range.location != textBox.attributedString().length else {
            document.selectedNode = .none
            return
        }
        
        // Move the range start caret back one character to create a selection
        let location = range.location - 1
        guard location > 0 else {
            document.selectedNode = .none
            return
        }
        
        let newRange = NSMakeRange(location, 1)
        
        guard let (line, position) = getPathComponents(in: textBox, at: newRange) else {
            document.selectedNode = .none
            return
        }
        
        // Move position point forward one a
        let newPosition = position + 1
        guard newPosition > 1 else {
            document.selectedNode = .none
            return
        }
        
        document.currentLine = line
        document.selectedNode = .insertion(position: newPosition)
    }
    
    func getPathComponents(in textBox: NSTextView, at range: NSRange) -> (line: Int, position: Int)? {
        guard let str = textBox.attributedSubstring(forProposedRange: range, actualRange: nil) else { return nil }
        let attributes = str.attributes(at: 0, effectiveRange: nil)
        guard let reference = attributes[.reference] as? String else { return nil  }
        let pathComponents = reference.split(separator: ".")
        let path = pathComponents.compactMap{Int($0)}
        
        // Validate line and location
        guard path.count == 2,
            let line = document.nodes[path[0]],
            line.count > path[1] else {return nil}
        
        return (line: path[0], position: path[1])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshView()
        ocdlView.ocdlDelegate = self
        document.ocdlDelegate = self
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            refreshView()
        }
    }
    
    func deleteNode() {
       document.deleteNode()
    }
    
}


