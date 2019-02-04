//
//  OraccCDLNode+ExtractLemma.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 04/02/2019.
//  Copyright © 2019 Chaitanya Kanchan. All rights reserved.
//

import Foundation
import CDKSwiftOracc

extension OraccCDLNode {
    static func extractLemmaData(from node: OraccCDLNode) -> (normalisation: String, transliteration: String, translation: String, textID: TextID, position: Int)? {
        guard case let OraccCDLNode.l(lemma) = node else {return nil}
        let normalisation = lemma.wordForm.form
        let transliteration = lemma.fragment
        let translation = lemma.wordForm.translation.sense ?? ""
        let textID = lemma.reference.base
        let position = Int(lemma.reference.path.last!)!
        return (
            normalisation: normalisation,
            transliteration: transliteration,
            translation: translation,
            textID: textID,
            position: position
        )
    }
}
