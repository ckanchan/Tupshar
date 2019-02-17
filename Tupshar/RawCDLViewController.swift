//
//  RawCDLViewController.swift
//  Tupshar: cuneiform text editor
//  Copyright (C) 2019 Chaitanya Kanchan
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

class RawCDLViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    static func New(forDocument document: Document, viewDelegate: OCDLViewDelegate?) -> (NSWindowController, RawCDLViewController)? {
        let storyboard = NSStoryboard(name: "Advanced", bundle: nil)
        guard let wc = storyboard.instantiateController(withIdentifier: "rawCDLWindow") as? NSWindowController,
            let vc = wc.contentViewController as? RawCDLViewController else {return nil}
        
        vc.documentReference = document
        return (wc, vc)
    }
    
    weak var ocdlViewDelegate: OCDLViewDelegate?
    @IBOutlet weak var cdlTableView: NSTableView!
    var documentReference: Document? {
        didSet {
            cdlTableView.reloadData()
            NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: .documentChanged, object: documentReference)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        cdlTableView.dataSource = self
        cdlTableView.delegate = self
    }
    
    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refreshView() {
        self.cdlTableView.reloadData()
    }
    
    func getRowLabels(for node: OraccCDLNode) -> (line: String, position: String, kind: String, transliteration: String, normalisation: String, translation: String)? {
        
        switch node {
        case .l(let lemma):
            return (line: lemma.reference.path[0],
                    position: lemma.reference.path[1],
                    kind: "Lemma",
                    transliteration: lemma.fragment,
                    normalisation: lemma.wordForm.normalisation ?? "",
                    translation: lemma.wordForm.translation.guideWord ?? "")
        case .d(let discontinuity):
            return (line: discontinuity.label ?? "",
                    position: "",
                    kind: discontinuity.type.rawValue,
                    transliteration: "",
                    normalisation: "",
                    translation: "")
        default:
            return nil
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return documentReference?.text.cdl.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let document = self.documentReference,
            let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {return nil}

        let node = document.text.cdl[row]

        guard let labels = getRowLabels(for: node) else {return nil}
        let isLemma = labels.kind == "Lemma"
        view.textField?.isEditable = isLemma
        
        switch tableColumn?.identifier.rawValue {
        case "line": view.textField?.stringValue = labels.line
        case "position": view.textField?.stringValue = labels.position
        case "kind": view.textField?.stringValue = labels.kind
            view.textField?.isEditable = false
        case "transliteration": view.textField?.stringValue = labels.transliteration
        case "normalisation": view.textField?.stringValue = labels.normalisation
        case "translation": view.textField?.stringValue = labels.translation
        default: return nil
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let objectValue: String
        
        switch tableColumn?.identifier.rawValue {
        case "line": objectValue = "line"
        case "position": objectValue = "position"
        case "kind": objectValue = "kind"
        case "transliteration": objectValue = "transliteration"
        case "normalisation": objectValue = "normalisation"
        case "translation": objectValue = "translation"
        default: return nil
            
        }
        
        return objectValue
    }

    @IBAction func didEditNode(_ sender: NSTextField) {
        guard let document = self.documentReference,
            let tableViewCell = sender.superview as? NSTableCellView,
            let column = tableViewCell.objectValue as? String else {return}
        
        let row = cdlTableView.selectedRow
        let node = document.text.cdl[row]
        
        guard case var OraccCDLNode.l(lemma) = node else {return}
        let newNode: OraccCDLNode
        
        switch column {
        case "line":
            guard let newLine = Int(sender.stringValue),
                let oldLine = Int(lemma.reference.path[0]),
                oldLine != newLine else {return}
            lemma.reference.path[0] = String(newLine)
            newNode = OraccCDLNode.l(lemma)
            document.updateNode(oldNode: node, newNode: newNode)
        case "position":
            guard let newPosition = Int(sender.stringValue),
                let oldPosition = Int(lemma.reference.path[1]),
                newPosition != oldPosition else {return}
            lemma.reference.path[1] = String(newPosition)
            newNode = OraccCDLNode.l(lemma)
            
            
        case "transliteration":
            guard let lemmaValues = node.extractLemmaData(),
                lemmaValues.transliteration != sender.stringValue else {return}
            let newLemma = OraccCDLNode(normalisation: lemmaValues.normalisation,
                                        transliteration: sender.stringValue,
                                        translation: lemmaValues.translation,
                                        cuneifier: cuneifier.cuneifySyllable,
                                        textID: lemmaValues.textID,
                                        line: lemmaValues.line,
                                        position: lemmaValues.position)
            
            newNode = newLemma
            
        case "normalisation":
            guard let lemmaValues = node.extractLemmaData(),
                lemmaValues.normalisation != sender.stringValue else {return}
            let newLemma = OraccCDLNode(normalisation: sender.stringValue,
                                        transliteration: lemmaValues.transliteration,
                                        translation: lemmaValues.translation,
                                        cuneifier: cuneifier.cuneifySyllable,
                                        textID: lemmaValues.textID,
                                        line: lemmaValues.line,
                                        position: lemmaValues.position)
            
            newNode = newLemma
        case "translation":
            guard let lemmaValues = node.extractLemmaData(),
                lemmaValues.translation != sender.stringValue else {return}
            let newLemma = OraccCDLNode(normalisation: lemmaValues.normalisation,
                                        transliteration: lemmaValues.transliteration,
                                        translation: sender.stringValue,
                                        cuneifier: cuneifier.cuneifySyllable,
                                        textID: lemmaValues.textID,
                                        line: lemmaValues.line,
                                        position: lemmaValues.position)
            
            newNode = newLemma

        default:
            return
        }

        document.updateNode(oldNode: node, newNode: newNode)
    }
}
