//
//  String+ReplaceATF.swift
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

extension String {
    static let atfMap = ["SZ":"Š",
                         "sz": "š",
                         ",S":"Ṣ",
                         ",s":"ṣ",
                         ",T":"Ṭ",
                         ",t":"ṭ"]
    
    
    /// This method replaces a basic set of ASCII abbreviations with their Unicode forms. The abbreviations
    /// are based on the the [ATF Inline convention](http://oracc.org/doc/help/editinginatf/primer/inlinetutorial/index.html)
    /// but with the trailing comma now a leading comma. This allows for unambiguous insertion of these
    /// patterns in texts following typical whitespace usages.
    /// - Returns: A copy of `self` with ATF sequences replaced with Unicode forms
    func replaceATF() -> String {
        var result = self
        let pattern = "(" + String.atfMap.keys.joined(separator: "|") + ")"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: result, options: [], range: NSMakeRange(0, result.count))
        matches.reversed().forEach { match in
            guard let range = Range(match.range, in: result) else {return}
            let subStr = String(result[range])
            if let replacement = String.atfMap[subStr] {
                result.replaceSubrange(range, with: replacement)
            }
        }
        return result
    }
}
