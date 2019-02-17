//
//  DocumentExports.swift
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

extension Document {
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
