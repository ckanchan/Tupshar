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
    
    var nodes: [Int: [OraccCDLNode]] = [:] {
        didSet {
            let cdl = nodes.flattened()
            self.text = OraccTextEdition(type: "modern", project: metadata.project, cdl: Array(cdl), textID: textID)
            self.ocdlDelegate?.refreshView()
            notifyDocumentChanged()
        }
    }
    
    var selectedNode: Int? {
        didSet {
            if selectedNode == nil {
                currentLine = nodes.count
            }
        }
    }
    
    var currentLine = 1 {
        didSet {
            if !nodes.keys.contains(currentLine) {
                nodes[currentLine] = [OraccCDLNode(lineBreakLabel: "\(currentLine)")]
            }
        }
    }
    
    var cuneifier: Cuneifier {
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        return delegate.cuneifier
    }
    
    weak var ocdlDelegate: OCDLViewDelegate?
    
    @IBAction func showAdvancedNodes(_ sender: Any) {
        guard let (wc, _) = RawCDLViewController.New(forDocument: self, viewDelegate: ocdlDelegate) else {return}
        wc.window?.title = metadata.title + "- Node View"
        wc.showWindow(self)
    }
    
    func notifyDocumentChanged() {
        let notification = Notification(name: .documentChanged, object: self)
        NotificationCenter.default.post(notification)
    }
    
    func insertNode(_ node: OraccCDLNode) {
        switch node {
        case .l(let lemma):
            let lineNumber = Int(lemma.reference.path[0]) ?? currentLine
            var line = nodes[lineNumber] ?? [OraccCDLNode(lineBreakLabel: "\(lineNumber)")]
            line.append(node)
            nodes[lineNumber] = line
            
        default:
            return
        }
    }
    
    func deleteNode(line lineNumber: Int, position: Int) {
        guard var line = nodes[lineNumber] else {return}
        if position < line.count - 1 {
            let pre = Array(line.prefix(upTo: position))
            let post = Array(line.suffix(from: position).dropFirst())
            let corrected = post.map { node -> OraccCDLNode in
                return node.updatePosition{ $0 - 1 }
            }
            line = pre + corrected
        } else {
            line.remove(at: position)
        }
        
        nodes[lineNumber] = line
        ocdlDelegate?.refreshView()
        notifyDocumentChanged()
    }
    
    func deleteNode() {
        guard let nodeIdx = selectedNode,
            !nodes.isEmpty else {return}
        
        deleteNode(line: currentLine, position: nodeIdx)
        selectedNode = nil
    }
    
    func updateNode(oldNode: OraccCDLNode, newNode: OraccCDLNode) {
        guard case let OraccCDLNode.l(oldLemma) = oldNode,
            case let OraccCDLNode.l(newLemma) = newNode else {return}
        
        let oldLine = Int(oldLemma.reference.path[0])!
        let oldPosition = Int(oldLemma.reference.path[1])!
        let newLine = Int(newLemma.reference.path[0])!
        let newPosition = Int(newLemma.reference.path[1])!
        
        if (oldLine, oldPosition) == (newLine, newPosition) {
            guard var line = nodes[oldLine] else {return}
            line[oldPosition] = newNode
            nodes[newLine] = line
        } else {
            
            deleteNode(line: oldLine, position: oldPosition)
            
            var line = nodes[newLine] ?? [OraccCDLNode(lineBreakLabel: "\(newLine)")]
            if line.count > newPosition {
                let pre = Array(line.prefix(upTo: newPosition))
                let post = Array(line.suffix(from: newPosition))
                let corrected = post.map { node -> OraccCDLNode in
                    return node.updatePosition {$0 + 1}
                }
                
                let updatedLine = pre + [newNode] + corrected
                line = updatedLine
            } else {
                
                guard case var OraccCDLNode.l(newLemma) = newNode else {return}
                newLemma.reference.path[1] = String(line.count)
                let correctedNode = OraccCDLNode.l(newLemma)
                line.append(correctedNode)
            }
            
            nodes[newLine] = line
        }
        ocdlDelegate?.refreshView()
        notifyDocumentChanged()
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

        self.nodes = [1: [OraccCDLNode(lineBreakLabel: "1")]]
        self.text = OraccTextEdition(type: "modern",
                                     project: self.metadata.project,
                                     cdl: self.nodes.flattened(),
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
            
            nodes = nodeLines
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
            .documentType: NSAttributedString.DocumentType.officeOpenXML,
            .title: metadata.title,
            .author: metadata.ancientAuthor ?? ""
        ]
        
        let data = try? docstring.data(from: NSMakeRange(0, docstring.length), documentAttributes: docAttributes)
        
        return data
    }
}

extension Dictionary where Key: Comparable, Value: Collection {
    func flattened() -> Array<Value.Element> {
        let flattened = self.sorted(by: {$0.key < $1.key})
            .map({$0.value})
            .joined()
        return Array(flattened)
    }
}

extension Notification.Name {
    static var documentChanged: Notification.Name {
        return Notification.Name("documentChanged")
    }
}
