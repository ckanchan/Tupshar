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
    
    var nodes: [Int: [OraccCDLNode]] = [:] {
        didSet {
            let cdl = nodes.flattened()
            self.text = OraccTextEdition(type: "modern", project: metadata.project, cdl: Array(cdl), textID: textID)
            self.ocdlDelegate?.refreshView()
            notifyDocumentChanged()
        }
    }
    
    var cursorPosition: Cursor = .append(line: 1, position: 1) {
        didSet {
            if nodes[cursorPosition.line] == nil {
                nodes[cursorPosition.line] = [OraccCDLNode(lineBreakLabel: "\(cursorPosition.line)")]
            }
            let notification = Notification(name: .nodeSelected, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
    
    
    var cuneifier: Cuneifier {
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        return delegate.cuneifier
    }
    
    weak var ocdlDelegate: OCDLViewDelegate?
    
    @IBAction func showAdvancedNodes(_ sender: Any) {
        guard let (wc, _) = RawCDLViewController.New(forDocument: self, viewDelegate: ocdlDelegate) else {return}
        wc.window?.title = metadata.title + " - Node View"
        wc.showWindow(self)
    }
    
    func notifyDocumentChanged() {
        let notification = Notification(name: .documentChanged, object: self)
        NotificationCenter.default.post(notification)
    }
    
    func incrementLine() {
        let newLine = cursorPosition.line + 1
        let newPosition = nodes[newLine]?.count ?? 1
        cursorPosition = .append(line: newLine, position: newPosition)
    }
    
    func appendLemma(normalisation: String, transliteration: String, translation: String) {
        guard case let Cursor.append(line: lineNumber, position: position) = cursorPosition else {return}
        let lemma = OraccCDLNode(normalisation: normalisation.replaceATF(),
                                 transliteration: transliteration.replaceATF(),
                                 translation: transliteration.replaceATF(),
                                 cuneifier: cuneifier.cuneifySyllable,
                                 textID: textID,
                                 line: lineNumber,
                                 position: position)
        var line = nodes[lineNumber, default: [OraccCDLNode(lineBreakLabel: String(lineNumber))]]
        line.append(lemma)
        nodes[lineNumber] = line
        cursorPosition = .append(line: lineNumber, position: position + 1)
    }
    
    
    func insertLemma(normalisation: String, transliteration: String, translation: String) {
        guard case let Cursor.insertion(line: lineNumber, position: position) = cursorPosition else {return}
        var line = nodes[lineNumber, default: [OraccCDLNode(lineBreakLabel: String(lineNumber))]]
        
        // Check if the position is validly in the middle of the line
        if line.count > position {
            let pre = Array(line.prefix(upTo: position))
            let post = Array(line.suffix(from: position))
            let corrected = post.map { node -> OraccCDLNode in
                return node.updatePosition{ $0 + 1 }
            }
            
            let lemma = OraccCDLNode(normalisation: normalisation,
                                     transliteration: transliteration,
                                     translation: translation,
                                     cuneifier: cuneifier.cuneifySyllable,
                                     textID: textID,
                                     line: lineNumber,
                                     position: position)
            
            line = pre + [lemma] + corrected
            nodes[lineNumber] = line
            setCursorToEnd()

            // otherwise append at the end of the line
        } else {
            cursorPosition = .append(line: lineNumber, position: line.count)
            appendLemma(normalisation: normalisation,
                        transliteration: transliteration,
                        translation: translation)

        }
    }
    
    func deleteNode() {
        guard case let Cursor.selection(line: lineNumber, position: position) = cursorPosition else {return}

        deleteNode(lineNumber: lineNumber, position: position)
        cursorPosition = .append(line: nodes.count, position: nodes[nodes.count]?.count ?? 0)
    }
    
    func deleteNode(lineNumber: Int, position: Int) {
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
    }
    
    func modifyLemma(normalisation: String, transliteration: String, translation: String) {
        guard case let Cursor.selection(line: lineNumber, position: position) = cursorPosition,
            var line = nodes[lineNumber] else {return}

        let lemma = OraccCDLNode(normalisation: normalisation,
                                 transliteration: transliteration,
                                 translation: translation,
                                 cuneifier: cuneifier.cuneifySyllable,
                                 textID: textID,
                                 line: lineNumber,
                                 position: position)
        
        line[position] = lemma
        nodes[lineNumber] = line
    }
    
    func updateNode(oldNode: OraccCDLNode, newNode: OraccCDLNode) {
        guard case let OraccCDLNode.l(oldLemma) = oldNode,
            case let OraccCDLNode.l(newLemma) = newNode else {return}
        
        let oldLine = Int(oldLemma.reference.path[0])!
        let oldPosition = Int(oldLemma.reference.path[1])!
        let newLine = Int(newLemma.reference.path[0])!
        let newPosition = Int(newLemma.reference.path[1])!
        
        // Modify the node in place
        
        if (oldLine, oldPosition) == (newLine, newPosition) {
            guard var line = nodes[oldLine] else {return}
            line[oldPosition] = newNode
            nodes[newLine] = line
        } else {
            
            // The node has been moved -- delete the old node and insert the new node at its new position
            deleteNode(lineNumber: oldLine, position: oldPosition)
            
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
    }
    
    func setCursorToEnd() {
        let documentEndPosition = nodes[nodes.count, default: [OraccCDLNode(lineBreakLabel: String(nodes.count))]].count
        cursorPosition = .append(line: nodes.count, position: documentEndPosition)
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
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        let cuneifier = delegate.cuneifier
        
        self.nodeStore = NodeStore(textID: self.textID, cuneifier: cuneifier)
        
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
    static var nodeSelected: Notification.Name {
        return Notification.Name("nodeSelected")
    }
}
