//
//  String+CuneifyExtensions.swift
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

extension String {
    static var combiningAcuteAccent: String {
        let scalar = Unicode.Scalar(0x301)!
        return String(scalar)
    }
    
    static var combiningGraveAccent: String {
        let scalar = Unicode.Scalar(0x300)!
        return String(scalar)
    }
}

extension String {
    func cuneifyInputEncoded() -> String {
        if self.decomposedStringWithCanonicalMapping.contains(String.combiningAcuteAccent) {
            return self.decomposedStringWithCanonicalMapping.replacingOccurrences(of: String.combiningAcuteAccent, with: "").appending("₂")
        } else if self.decomposedStringWithCanonicalMapping.contains(String.combiningGraveAccent) {
            return self.decomposedStringWithCanonicalMapping.replacingOccurrences(of: String.combiningGraveAccent, with: "").appending("₃")
        } else if self.contains("3") {
            return self.replacingOccurrences(of: "3", with: "₃")
        } else {
            return self
        }
    }
}

