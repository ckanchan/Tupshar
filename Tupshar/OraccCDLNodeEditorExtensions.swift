//
//  OraccCDLNodeEditorExtensions.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 27/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

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
