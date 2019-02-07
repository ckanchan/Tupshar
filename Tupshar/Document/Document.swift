//
//  Document.swift
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

class Document: NSDocument {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    var textID: TextID
    var metadata: OraccCatalogEntry
    var text: OraccTextEdition
    var translation: String
    
    var nodes: [OraccCDLNode] = [] {
        didSet {
            self.text = OraccTextEdition(type: "modern", project: metadata.project, cdl: nodes, textID: textID)
            self.ocdlDelegate?.refreshView()
        }
    }
    
    var selectedNode: Int?
    
    weak var ocdlDelegate: OCDLViewDelegate?
    
    
    override init() {
        let uuid = UUID().uuidString
        let textIDStr = "U" + uuid
        self.textID = TextID.init(stringLiteral: textIDStr)
        self.metadata = OraccCatalogEntry(id: self.textID,
                                          displayName: "New Document",
                                          ancientAuthor: nil,
                                          title: "New Document",
                                          project: "Unassigned")

        self.text = OraccTextEdition(type: "modern",
                                     project: self.metadata.project,
                                     cdl: [],
                                     textID: self.textID)
        
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
            nodes = decoded.text.cdl
            textID = decoded.metadata.id
            metadata = decoded.metadata
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
        panel.allowedFileTypes = ["doc"]
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
    
    func convertToText() -> Data? {
        let cuneiform = text.cuneiform
        let transliteration  = text.transliteration
        let normalisation = text.transcription
        let translation = self.translation
        
        let exported = ExportedText(cuneiform: cuneiform,
                                    transliteration: transliteration,
                                    normalisation: normalisation,
                                    translation: translation)
        
        guard let exportedData = try? encoder.encode(exported) else {return nil}
        return exportedData
    }
    
    func convertToDoc() -> Data? {
        let exportFormatting = NSFont(name: "Helvetica", size: NSFont.systemFontSize)!.makeDefaultPreferences()
        let cuneiformNA = NSFont(name: "CuneiformNAOutline Medium", size: NSFont.systemFontSize)!
        
        let cuneiform = NSMutableAttributedString(string: text.cuneiform)
        cuneiform.addAttributes([NSAttributedString.Key.font: cuneiformNA], range: NSMakeRange(0, cuneiform.length))
        
        let transliteration = text.transliterated().render(withPreferences: exportFormatting)
        let normalisation = text.normalised().render(withPreferences: exportFormatting)
        let attributedTranslation = NSAttributedString(string: translation)
        let lineBreak = NSAttributedString(string: "\n\n")
        
        let strings = [cuneiform, lineBreak, transliteration, lineBreak, normalisation, lineBreak, attributedTranslation]
        let docstring = NSMutableAttributedString()
        strings.forEach{docstring.append($0)}
        
        let docAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.docFormat,
            .title: metadata.title,
            .author: metadata.ancientAuthor ?? ""
        ]
        
        
        let data = docstring.docFormat(from: NSMakeRange(0, docstring.length), documentAttributes: docAttributes)
        
        return data
    }
}
