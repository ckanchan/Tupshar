//
//  Cuneify.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 25/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

import Foundation

struct OSLSign: Codable {
    var sign: String
    var unicodeName: String
    var characterCode: String
    var utf8: String
    var values: [String]
}

struct LocalCuneifier {
    var signDictionary: [String: String]
    
    func cuneifySyllable(_ syll: String) -> String? {
        let input = syll.cuneifyInputEncoded()
        return self.signDictionary[input] ?? "[X]"
    }
    
    init(json: Data) throws {
        let decoder = JSONDecoder()
        let list = try decoder.decode([OSLSign].self, from: json)
        var dictionary: [String:String] = [:]
        list.forEach { sign in
            sign.values.forEach { value in
                dictionary[value] = sign.utf8
            }
        }
        
        self.signDictionary = dictionary
    }

    init(withDictionary dictionary: [String:String]) {
        self.signDictionary = dictionary
    }

}

