//
//  ViewController.swift
//  Tupshar: novelty cuneiform text editor
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
    let cuneiformNA = NSFont.init(name: "CuneiformNAOutline Medium", size: NSFont.systemFontSize)
    
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
            document.selectedNode = nil
            return
        }
        
        guard let str = textBox.attributedSubstring(forProposedRange: range, actualRange: nil) else {
            document.selectedNode = nil
            return
        }
        
        let attributes = str.attributes(at: 0, effectiveRange: nil)
        guard let reference = attributes[.reference] as? String else {
            document.selectedNode = nil
            return
        }
        let pathComponents = reference.split(separator: ".")
        let path = pathComponents.compactMap{Int($0)}
        guard path.count == 2 else {
            document.selectedNode = nil
            return
        }
        
        document.currentLine = path[0]
        document.selectedNode = path[1]
        
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
        if let nodeIdx = document.selectedNode {
            guard !document.nodes.isEmpty else {
                print("error")
                return
            }
            
            guard var line = document.nodes[document.currentLine] else {return}
            
            // If the deleted node is in the middle of text, then all node references following the deleted node need to be updated with new index numbers
            if nodeIdx < line.count - 1 {
                let pre = Array(line.prefix(upTo: nodeIdx))
                let post = Array(line.suffix(from: nodeIdx).dropFirst())
                let corrected = post.compactMap { node -> OraccCDLNode? in
                    guard let (normalisation, transliteration, translation, documentID, position) = OraccCDLNode.extractLemmaData(from: node) else {return nil}
                    let newPosition = position - 1
                    let newNode = OraccCDLNode(normalisation: normalisation, transliteration: transliteration, translation: translation, cuneifier: cuneifier.cuneifySyllable, textID: documentID, line: 0, position: newPosition)
                    return newNode
                }
                line = pre + corrected
            } else {
                line.remove(at: nodeIdx)
            }
            document.nodes[document.currentLine] = line
            document.selectedNode = nil
            refreshView()
        }
    }
    
}


