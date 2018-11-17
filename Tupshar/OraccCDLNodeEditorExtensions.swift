//
//  OraccCDLNodeEditorExtensions.swift
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

import Foundation
import CDKSwiftOracc

extension OraccCDLNode {
    var lemmaReference: String {
        switch self {
        case .l(let lemma):
            return lemma.reference.description
        default:
            return ""
        }
    }
    
    
    static func makeLemma(normalisation: String, transliteration: String, translation: String, cuneifier: ((String) -> String?)) -> (String, OraccCDLNode) {
        
        var graphemes = [GraphemeDescription]()
        let syllables = transliteration.split(separator: "-")
        for syllable in syllables.dropLast() {
            let grapheme = OraccCDLNode.makeGrapheme(syllable: String(syllable), delimiter: "-", cuneifier: cuneifier)
            graphemes.append(grapheme)
        }
        
        graphemes.append(makeGrapheme(syllable: String(syllables.last!), delimiter: " ", cuneifier: cuneifier))
        
        
        let transl = WordForm.Translation(guideWord: translation, citationForm: nil, sense: translation, partOfSpeech: nil, effectivePartOfSpeech: nil)
        let wordForm = WordForm(language: .Akkadian(.conventional), form: normalisation, graphemeDescriptions: graphemes, normalisation: normalisation, translation: transl, delimiter: " ")
        
        let referenceString = "U\(UUID().uuidString).0.0"
        let reference = NodeReference.init(stringLiteral: referenceString)
        
        let lemma = OraccCDLNode.Lemma(fragment: transliteration, instanceTranslation: nil, wordForm: wordForm, reference: reference)
        let node = OraccCDLNode.l(lemma)
        return (reference.description, node)
        
    }
    
    static func makeGrapheme(syllable: String, delimiter: String, cuneifier: ((String) -> String?)) -> GraphemeDescription {
        let sign: CuneiformSignReading
        var logogram = false
        if syllable.uppercased() == syllable {
            // It's a logogram, encode it as such
            sign = .name(String(syllable))
            logogram = true
        } else {
            sign = .value(String(syllable))
        }
        
        let grapheme = GraphemeDescription(graphemeUTF8: cuneifier(String(syllable)), sign: sign, isLogogram: logogram, isDeterminative: nil, components: nil, delimiter: delimiter)
        
        return grapheme
    }
}
