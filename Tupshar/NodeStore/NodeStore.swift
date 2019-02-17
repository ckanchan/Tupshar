//
//  NodeStore.swift
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

import Foundation
import CDKSwiftOracc

class NodeStore {
    let textID: TextID
    let cuneifier: Cuneifier
    
    var nodes: [Int: [OraccCDLNode]]
    var cursorPosition: Cursor = .append(line: 1, position: 1) {
        didSet {
            if nodes[cursorPosition.line] == nil {
                nodes[cursorPosition.line] = [OraccCDLNode(lineBreakLabel: "\(cursorPosition.line)")]
            }
            let notification = Notification(name: .nodeSelected, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
    
    func setCursorToEnd() {
        let documentEndPosition = nodes[nodes.count, default: [OraccCDLNode(lineBreakLabel: String(nodes.count))]].count
        cursorPosition = .append(line: nodes.count, position: documentEndPosition)
    }
    
    func incrementLine() {
        let newLine = cursorPosition.line + 1
        let newPosition = nodes[newLine]?.count ?? 1
        cursorPosition = .append(line: newLine, position: newPosition)
    }
    
    func createTextEdition(project: String) -> OraccTextEdition {
        return OraccTextEdition(type: "modern",
                                project: project,
                                cdl: nodes.flattened(),
                                textID: textID)
    }
    
    init(textID: TextID, cuneifier: Cuneifier, nodes: [Int:[OraccCDLNode]] = [1:[OraccCDLNode(lineBreakLabel: "1")]]) {
        self.textID = textID
        self.nodes = nodes
        self.cuneifier = cuneifier
    }
}

extension NodeStore: NodeStoring {
    func appendLemma(normalisation: String, transliteration: String, translation: String) {
        guard case let Cursor.append(line: lineNumber, position: position) = cursorPosition else {return}
        let lemma = OraccCDLNode(normalisation: normalisation.replaceATF(),
                                 transliteration: transliteration.replaceATF(),
                                 translation: translation,
                                 cuneifier: cuneifier.cuneifySyllable,
                                 textID: textID,
                                 line: lineNumber,
                                 position: position)
        var line = nodes[lineNumber, default: [OraccCDLNode(lineBreakLabel: String(lineNumber))]]
        line.append(lemma)
        nodes[lineNumber] = line
        cursorPosition = .append(line: lineNumber, position: position + 1)
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
}
