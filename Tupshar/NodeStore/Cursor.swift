//
//  Cursor.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 16/02/2019.
//  Copyright © 2019 Chaitanya Kanchan. All rights reserved.
//

import Foundation

enum Cursor {
    case append(line: Int, position: Int)
    case insertion(line: Int, position: Int)
    case selection(line: Int, position: Int)
    
    var line: Int {
        switch self {
        case .append(line: let l, position: _):
            return l
        case .insertion(line: let l, position: _):
            return l
        case.selection(line: let l, position: _):
            return l
        }
    }
    
    var position: Int {
        switch self {
        case .append(line: _, position: let p):
            return p
        case .insertion(line: _, position: let p):
            return p
        case.selection(line: _, position: let p):
            return p
        }
    }
}
