//
//  ViewController.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 25/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Cocoa
import CDKSwiftOracc

class ViewController: NSViewController, NSTextViewDelegate, OCDLViewDelegate {
    let defaultFormatting = NSFont.systemFont(ofSize: NSFont.systemFontSize).makeDefaultPreferences()
    let cuneiformNA = NSFont.init(name: "CuneiformNAOutline Medium", size: NSFont.systemFontSize)
    
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
            ocdlView.backgroundColor = NSColor.white
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
        if range.location == NSNotFound {return}
        
        guard let str = textBox.attributedSubstring(forProposedRange: range, actualRange: nil) else {return}
        
        let attributes = str.attributes(at: 0, effectiveRange: nil)
        guard let reference = attributes[.reference] as? String else {return}
        if let nodeIdx = document.nodes.index(where: {$0.lemmaReference == reference}) {
            document.selectedNode = nodeIdx
        }

    }
    
    
    
    @IBOutlet weak var textSelect: NSSegmentedControl!
    @IBOutlet var ocdlView: OCDLView!

    
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
            document.nodes.remove(at: nodeIdx)
            document.selectedNode = nil
            refreshView()
        }
    }
    
}


