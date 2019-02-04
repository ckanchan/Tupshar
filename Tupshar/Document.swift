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

enum LoadError: Error {
    case BadData
}

struct TupsharWrapper: Codable {
    var text: OraccTextEdition
    var translation: String
    var id: TextID
}

struct ExportedDocument: Codable {
    let cuneiform: String
    let transliteration: String
    let normalisation: String
    let translation: String
}


class Document: NSDocument {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    var textID: TextID
    
    var text: OraccTextEdition
    var translation: String
    var nodes: [OraccCDLNode] = [] {
        didSet {
            self.text = OraccTextEdition(withCDL: nodes, textID: textID)
            self.ocdlDelegate?.refreshView()
        }
    }
    
    var selectedNode: Int?
    
    weak var ocdlDelegate: OCDLViewDelegate?
    
    
    override init() {
        let uuid = UUID().uuidString
        let textIDStr = "U" + uuid
        self.textID = TextID.init(stringLiteral: textIDStr)
        self.text = OraccTextEdition.init(withCDL: [], textID: self.textID)
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
        let wrapper = TupsharWrapper(text: self.text, translation: self.translation, id: self.textID)
        return try encoder.encode(wrapper)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        if let decoded = try? decoder.decode(TupsharWrapper.self, from: data) {
            text = decoded.text
            translation = decoded.translation
            nodes = decoded.text.cdl
            textID = decoded.id
        } else {
            throw LoadError.BadData
        }
    }

    
    @IBAction func export(_ sender: Any){
        guard let window = self.windowControllers.first?.window else {return}
//        let cuneiform = text.cuneiform
//        let transliteration  = text.transliteration
//        let normalisation = text.transcription
//        let translation = self.translation
//
//        let exported = ExportedDocument(cuneiform: cuneiform, transliteration: transliteration, normalisation: normalisation, translation: translation)
//        guard let exportedData = try? encoder.encode(exported) else {return}
        
        guard let exportedData = convertToDoc() else {return}
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["doc"]
        panel.beginSheetModal(for: window) {modalResponse in
            if modalResponse == NSApplication.ModalResponse.OK {
                guard let url = panel.url else {return}
                do {
                    try exportedData.write(to: url)
                } catch {
                    Swift.print(error.localizedDescription)
                }
            }
            
        }
    }
    
    func convertToDoc() -> Data? {
        let exportFormatting = NSFont(name: "Helvetica", size: NSFont.systemFontSize)!.makeDefaultPreferences()
        let cuneiformNA = NSFont(name: "CuneiformNAOutline Medium", size: NSFont.systemFontSize)!
        
        let cuneiform = NSMutableAttributedString(string: text.cuneiform)
        cuneiform.addAttributes([NSAttributedString.Key.font: cuneiformNA], range: NSMakeRange(0, cuneiform.length))
        
        let transliteration = text.transliterated().render(withPreferences: exportFormatting)
        let normalisation = text.normalised().render(withPreferences: exportFormatting)
        let attributedTranslation = NSAttributedString(string: translation)
        let lineBreak = NSAttributedString(string: "\n")
        
        let strings = [cuneiform, lineBreak, transliteration, lineBreak, normalisation, lineBreak, attributedTranslation]
        let docstring = NSMutableAttributedString()
        strings.forEach{docstring.append($0)}
        
        let docAttributes = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.docFormat]
        let data = docstring.docFormat(from: NSMakeRange(0, docstring.length), documentAttributes: docAttributes)
        
        return data
    }
}

