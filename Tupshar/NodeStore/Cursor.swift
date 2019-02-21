//
//  Cursor.swift
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

enum Cursor {
    case append(line: Int, position: Int)
    case insertion(line: Int, position: Int)
    case selection(line: Int, position: Int)
    
    var line: Int {
        switch self {
        case .append(let line, _),
             .insertion(let line, _),
             .selection(let line, _):
            return line
        }
    }
    
    var position: Int {
        switch self {
        case .append(_, let position),
             .insertion(_, let position),
             .selection(_, let position):
            return position
        }
    }
}
