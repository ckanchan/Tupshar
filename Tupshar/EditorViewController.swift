//
//  EditorViewController.swift
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

class EditorViewController: NSViewController, NSTextViewDelegate {
    
    @IBOutlet weak var normalBox: NSTextField!
    @IBOutlet weak var translitBox: NSTextField!
    @IBOutlet weak var translateBox: NSTextField!
    
    @IBOutlet var documentTranslationBox: NSTextView!
    
    override func viewWillAppear() {
        documentTranslationBox.string = document.translation
    }

    
    @IBAction func insertNode(_ sender: Any) {
        if normalBox.stringValue.isEmpty || translitBox.stringValue.isEmpty || translateBox.stringValue.isEmpty {
            return
        } else {
            let lemma = OraccCDLNode(normalisation: normalBox.stringValue.replaceATF(),
                                     transliteration: translitBox.stringValue.replaceATF(),
                                     translation: translateBox.stringValue.replaceATF(),
                                     cuneifier: cuneifier.cuneifySyllable,
                                     textID: document.textID,
                                     line: 0,
                                     position: document.nodes.count)
            
            if let index = document.selectedNode {
                document.nodes.insert(lemma, at: index)
                document.selectedNode = nil
            } else {
                document.nodes.append(lemma)
            }
            
            view.window?.isDocumentEdited = true
        }
    }
    
    func textDidChange(_ notification: Notification) {
        let textBox = notification.object! as! NSTextView
        if textBox === self.documentTranslationBox {
            document.translation = documentTranslationBox.string
            view.window?.isDocumentEdited = true
        }
    }
}
