//
//  Cuneify.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 25/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Foundation

let inputXPath = "/html/body/p[1]"
let cuneiformOutputXPath = "/html/body/p[2]"
let unsafeChars = CharacterSet(charactersIn: "ḪḫŠšṢṣṬṭÁáÀàÉéÈèÍíÌìÚúÙù")

func cuneifySyllable(_ syll: String) -> String? {
    let inputURL = URL(string: "http://oracc.museum.upenn.edu/cgi-bin/cuneify?input=\(syll)")!
    
    guard let returnedData = try? XMLDocument(contentsOf: inputURL, options: .documentTidyHTML) else {return nil}
    guard let cuneiformElement = try? returnedData.nodes(forXPath: cuneiformOutputXPath) else {return nil}
    let str = String(cuneiformElement.first!.xmlString.dropLast(4))
    guard let idx = str.index(of: ">") else {return nil}
    let fIdx = str.index(after: idx)
    let cuneiform = str.suffix(from: fIdx)
    let trimmedCuneiform = cuneiform.trimmingCharacters(in: CharacterSet.newlines)
    return String(trimmedCuneiform)
}

