//
//  OraccCDLNode+ExtractLemma.swift
//  Tupshar: novelty cuneiform text editor
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

extension OraccCDLNode {
    static func extractLemmaData(from node: OraccCDLNode) -> (normalisation: String, transliteration: String, translation: String, textID: TextID, line: Int, position: Int)? {
        guard case let OraccCDLNode.l(lemma) = node else {return nil}
        let normalisation = lemma.wordForm.form
        let transliteration = lemma.fragment
        let translation = lemma.wordForm.translation.sense ?? ""
        let textID = lemma.reference.base
        let line = Int(lemma.reference.path[0])!
        let position = Int(lemma.reference.path[1])!
        return (
            normalisation: normalisation,
            transliteration: transliteration,
            translation: translation,
            textID: textID,
            line: line,
            position: position
        )
    }
    
    func updatePosition(by: (Int) -> Int) -> OraccCDLNode {
        guard case var OraccCDLNode.l(lemma) = self else {return self}
        let oldPosition = Int(lemma.reference.path[1])!
        let newPosition = by(oldPosition)
        lemma.reference.path[1] = String(newPosition)
        return OraccCDLNode.l(lemma)
    }
}
