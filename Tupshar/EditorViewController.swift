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
        NotificationCenter.default.addObserver(self, selector: #selector(displaySelectedNode), name: NSNotification.Name.nodeSelected, object: document)
        documentTranslationBox.string = document.translation
    }
    
    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func displaySelectedNode() {
        guard case let Document.Cursor.selection(position: currentPosition) = document.selectedNode,
            let node = document.nodes[document.currentLine]?[currentPosition],
            let values = OraccCDLNode.extractLemmaData(from: node) else {clearBoxes(); return}
        
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
            document.currentLine += 1
        case (false, false, false) :
            let position: Int
            
            if case let Document.Cursor.selection(position: currentPosition) = document.selectedNode {
                position = currentPosition
            } else {
                position = document.nodes[document.currentLine]?.count ?? 1
            }
            
            let lemma = OraccCDLNode(normalisation: normalBox.stringValue.replaceATF(),
                                     transliteration: translitBox.stringValue.replaceATF(),
                                     translation: translateBox.stringValue.replaceATF(),
                                     cuneifier: cuneifier.cuneifySyllable,
                                     textID: document.textID,
                                     line: document.currentLine,
                                     position: position)
            
            switch document.selectedNode {
            case .none:
                document.appendNode(lemma)
            case .insertion(let position):
                document.insertNode(lemma, at: position)
            case .selection(let position):
                guard let node = document.nodes[document.currentLine]?[position] else {return}
                document.updateNode(oldNode: node, newNode: lemma)
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
