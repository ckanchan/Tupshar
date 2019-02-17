//
//  EditorViewController.swift
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

class EditorViewController: NSViewController, NSTextViewDelegate {
    
    @IBOutlet weak var normalBox: NSTextField!
    @IBOutlet weak var translitBox: NSTextField!
    @IBOutlet weak var translateBox: NSTextField!
    
    @IBOutlet var documentTranslationBox: NSTextView!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(displaySelectedNode), name: .nodeSelected, object: document)
        documentTranslationBox.string = document.translation
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func displaySelectedNode() {
        guard case let Cursor.selection(line: selectedLine, position: selectedPosition) = document.nodeStore.cursorPosition,
            let node = document.nodeStore.nodes[selectedLine]?[selectedPosition],
            let values = node.extractLemmaData() else {clearBoxes(); return}
        
        normalBox.stringValue = values.normalisation
        translitBox.stringValue = values.transliteration
        translateBox.stringValue = values.translation
    }

    func clearBoxes() {
        [ normalBox, translitBox, translateBox].forEach {
            $0?.stringValue = ""
        }
    }
    
    @IBAction func insertNode(_ sender: Any) {
        switch (normalBox.stringValue.isEmpty, translitBox.stringValue.isEmpty, translateBox.stringValue.isEmpty) {
        case (true, true, true) :
            document.nodeStore.incrementLine()
        case (false, false, false) :
            
            
            switch document.nodeStore.cursorPosition {
            case .append:
                document.appendLemma(normalisation: normalBox.stringValue,
                                     transliteration: translitBox.stringValue,
                                     translation: translateBox.stringValue)
            case .insertion:
                document.insertLemma(normalisation: normalBox.stringValue,
                                     transliteration: translitBox.stringValue,
                                     translation: translateBox.stringValue)
            case .selection:
                document.modifyLemma(normalisation: normalBox.stringValue,
                                     transliteration: translitBox.stringValue,
                                     translation: translateBox.stringValue)
            }
            
            
        default:
            return
        }
        document.updateChangeCount(.changeDone)
        view.window?.isDocumentEdited = true
    }
    
    func textDidChange(_ notification: Notification) {
        let textBox = notification.object! as! NSTextView
        if textBox === self.documentTranslationBox {
            document.translation = documentTranslationBox.string
            view.window?.isDocumentEdited = true
        }
    }
}
