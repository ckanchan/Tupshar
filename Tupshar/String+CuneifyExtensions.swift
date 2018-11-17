//
//  String+CuneifyExtensions.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 17/11/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

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

