//
//  Document+NodeStoring.swift
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

extension Document: NodeStoring {
    func appendLemma(normalisation: String, transliteration: String, translation: String) {
        nodeStore.appendLemma(normalisation: normalisation, transliteration: transliteration, translation: translation)
        updateTextEdition()
        notifyDocumentChanged()
    }
    
    func modifyLemma(normalisation: String, transliteration: String, translation: String) {
        nodeStore.modifyLemma(normalisation: normalisation, transliteration: transliteration, translation: translation)
        updateTextEdition()
        notifyDocumentChanged()
    }
    
    func insertLemma(normalisation: String, transliteration: String, translation: String) {
        nodeStore.insertLemma(normalisation: normalisation, transliteration: transliteration, translation: translation)
        updateTextEdition()
        notifyDocumentChanged()
    }
    
    func updateNode(oldNode: OraccCDLNode, newNode: OraccCDLNode) {
        nodeStore.updateNode(oldNode: oldNode, newNode: newNode)
        updateTextEdition()
        notifyDocumentChanged()
    }
    
    func deleteNode(lineNumber: Int, position: Int) {
        nodeStore.deleteNode(lineNumber: lineNumber, position: position)
        updateTextEdition()
        notifyDocumentChanged()
    }
    
    func deleteNode() {
        guard case let Cursor.selection(line: lineNumber, position: position) = nodeStore.cursorPosition else {return}
        deleteNode(lineNumber: lineNumber, position: position)
    }
}
