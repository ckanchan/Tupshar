//
//  Document.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 25/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Cocoa
import CDKSwiftOracc

enum LoadError: Error {
    case BadData
}

struct TupsharWrapper: Codable {
    var text: OraccTextEdition
    var translation: String
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
    
    var text: OraccTextEdition
    var translation: String
    var nodes: [OraccCDLNode] = [] {
        didSet {
            self.text = OraccTextEdition.createNewText(nodes: nodes)
            self.ocdlDelegate?.refreshView()
        }
    }
    
    var selectedNode: Int?
    weak var ocdlDelegate: OCDLViewDelegate?
    
    
    override init() {
        self.text = OraccTextEdition.createNewText()
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
        let wrapper = TupsharWrapper(text: self.text, translation: self.translation)
        return try encoder.encode(wrapper)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        if let decoded = try? decoder.decode(TupsharWrapper.self, from: data) {
            text = decoded.text
            translation = decoded.translation
            nodes = decoded.text.cdl
        } else {
            throw LoadError.BadData
        }
    }

    
    @IBAction func export(_ sender: Any){
        guard let window = self.windowControllers.first?.window else {return}
        let cuneiform = text.cuneiform
        let transliteration  = text.transliteration
        let normalisation = text.transcription
        let translation = self.translation
        
        let exported = ExportedDocument(cuneiform: cuneiform, transliteration: transliteration, normalisation: normalisation, translation: translation)
        guard let exportedData = try? encoder.encode(exported) else {return}
        
        let panel = NSSavePanel()
        let name = ".txt"
        panel.nameFieldStringValue = name
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
}

