//
//  EditorViewController.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 27/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Cocoa
import CDKSwiftOracc

extension NSViewController {
    var document: Document {
        let document = view.window?.windowController?.document as? Document
        assert(document != nil, "Unable to find document for viewcontroller")
        return document!
    }
    
    var cuneifier: LocalCuneifier {
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        return delegate.cuneifier
    }
}


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
            let (_, lemma) = OraccCDLNode.makeLemma(normalisation: normalBox.stringValue, transliteration: translitBox.stringValue, translation: translateBox.stringValue, cuneifier: cuneifier.cuneifySyllable)
            
            if let index = document.selectedNode {
                document.nodes.insert(lemma, at: index)
                document.selectedNode = nil
            } else {
                document.nodes.append(lemma)
            }
        }
    }
    
    func textDidChange(_ notification: Notification) {
        let textBox = notification.object! as! NSTextView
        if textBox === self.documentTranslationBox {
            document.translation = documentTranslationBox.string
        }
    }
    
    
    
}
