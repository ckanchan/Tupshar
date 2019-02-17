//
//  Document.swift
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

class Document: NSDocument {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    var textID: TextID
    var metadata: OraccCatalogEntry
    var text: OraccTextEdition
    var translation: String
    
    var nodeStore: NodeStore
    
    weak var ocdlDelegate: OCDLViewDelegate?
    
    @IBAction func showAdvancedNodes(_ sender: Any) {
        guard let (wc, _) = RawCDLViewController.New(forDocument: self, viewDelegate: ocdlDelegate) else {return}
        wc.window?.title = metadata.title + " - Node View"
        wc.showWindow(self)
    }
    
    func updateTextEdition() {
        self.text = nodeStore.createTextEdition(project: metadata.project)
        ocdlDelegate?.refreshView()
    }
    
    func notifyDocumentChanged() {
        let notification = Notification(name: .documentChanged, object: self)
        NotificationCenter.default.post(notification)
    }
    
    override init() {
        let uuid = UUID().uuidString
        let textIDStr = "U" + uuid
        self.textID = TextID.init(stringLiteral: textIDStr)
        self.metadata = OraccCatalogEntry(id: self.textID,
                                          displayName: "New Document",
                                          ancientAuthor: nil,
                                          title: "New Document",
                                          project: "Unassigned")

        let delegate = NSApplication.shared.delegate! as! AppDelegate
        let cuneifier = delegate.cuneifier
        
        self.nodeStore = NodeStore(textID: self.textID, cuneifier: cuneifier)
        
        self.text = nodeStore.createTextEdition(project: metadata.project)
        
        self.translation = ""
        encoder.outputFormatting = .prettyPrinted
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        let wrapper = TupsharFile(text: self.text,
                                     metadata: self.metadata,
                                     translation: self.translation)
        return try encoder.encode(wrapper)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        if let decoded = try? decoder.decode(TupsharFile.self, from: data) {
            text = decoded.text
            translation = decoded.translation
            textID = decoded.metadata.id
            metadata = decoded.metadata
            
            let lemmas = decoded.text.cdl.compactMap { node -> OraccCDLNode.Lemma? in
                if case let OraccCDLNode.l(lemma) = node {
                    return lemma
                } else {
                    return nil
                }
            }
            
            let lines = Dictionary(grouping: lemmas, by: {Int($0.reference.path[0]) ?? 0})
            var nodeLines = lines.mapValues{$0.map({OraccCDLNode.l($0)})}
            for (lineNumber, line) in nodeLines {
                let lineStart = OraccCDLNode(lineBreakLabel: String(lineNumber))
                nodeLines[lineNumber] = [lineStart] + line
            }
            
            nodeStore.nodes = nodeLines
        } else {
            throw DocumentError.BadData
        }
    }

    
    @IBAction func exportAsText(_ sender: Any){
        guard let exportedData = self.convertToText() else {return}
        guard let window = self.windowControllers.first?.window else {return}
        let panel = NSSavePanel()
        let title = metadata.title
        panel.nameFieldStringValue = String(title)
        panel.allowedFileTypes = ["txt"]
        panel.message = "Export as Text File"
        panel.prompt = "Export"
        
        panel.beginSheetModal(for: window) {modalResponse in
            if modalResponse == NSApplication.ModalResponse.OK {
                do {
                    guard let url = panel.url else { throw DocumentError.FailedToExportData }
                    try exportedData.write(to: url)
                } catch {
                    Swift.print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func exportAsDoc(_ sender: Any) {
        guard let exportedData = self.convertToDoc() else {return}
        guard let window = self.windowControllers.first?.window else {return}
        let panel = NSSavePanel()
        let title = metadata.title
        panel.nameFieldStringValue = title
        panel.allowedFileTypes = ["docx"]
        panel.message = "Export as Microsoft Word Document"
        panel.prompt = "Export"
        
        panel.beginSheetModal(for: window) {modalResponse in
            if modalResponse == NSApplication.ModalResponse.OK {
                do {
                    guard let url = panel.url else { throw DocumentError.FailedToExportData }
                    try exportedData.write(to: url)
                } catch {
                    Swift.print(error.localizedDescription)
                }
            }
        }
    }
}
