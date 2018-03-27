//
//  OraccCDLNodeEditorExtensions.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 27/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Foundation
import OraccJSONtoSwift

extension OraccCDLNode {
    
    var lemmaReference: String {
        switch self.node {
        case .l(let lemma):
            return lemma.reference
        default:
            return ""
        }
    }
    
    
    static func makeLemma(normalisation: String, transliteration: String, translation: String) -> (String, OraccCDLNode) {
        
        var graphemes = [GraphemeDescription]()
        let syllables = transliteration.split(separator: "-")
        for syllable in syllables.dropLast() {
            let grapheme = OraccCDLNode.makeGrapheme(syllable: String(syllable), delimiter: "-")
            graphemes.append(grapheme)
        }
        
        graphemes.append(makeGrapheme(syllable: String(syllables.last!), delimiter: " "))
        
        
        let transl = WordForm.Translation(guideWord: translation, citationForm: nil, sense: translation, partOfSpeech: nil, effectivePartOfSpeech: nil)
        let wordForm = WordForm(language: .Akkadian(.conventional), form: normalisation, graphemeDescriptions: graphemes, normalisation: normalisation, translation: transl, delimiter: " ")
        
        let reference = UUID().uuidString
        
        let lemma = OraccCDLNode.Lemma(fragment: transliteration, instanceTranslation: nil, wordForm: wordForm, reference: reference)
        let node = OraccCDLNode.init(lemma: lemma)
        return (reference, node)
        
    }
    
    static func makeGrapheme(syllable: String, delimiter: String) -> GraphemeDescription {
        let sign: CuneiformSign
        var logogram = false
        if syllable.uppercased() == syllable {
            // It's a logogram, encode it as such
            sign = .name(String(syllable))
            logogram = true
        } else {
            sign = .value(String(syllable))
        }
        
        let grapheme = GraphemeDescription(graphemeUTF8: cuneifySyllable(String(syllable)), sign: sign, isLogogram: logogram, breakPosition: nil, isDeterminative: nil, group: nil, gdl: nil, sequence: nil, delimiter: delimiter)
        
        return grapheme
    }
}