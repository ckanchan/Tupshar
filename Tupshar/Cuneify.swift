//
//  Cuneify.swift
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

