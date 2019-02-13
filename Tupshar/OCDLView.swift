//
//  OCDLView.swift
//  Tupshar: cuneiform text editor
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

import Cocoa

class OCDLView: NSTextView {
    weak var ocdlDelegate: OCDLViewDelegate?
    
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        print("Cannot edit text directly")
    }

    override func deleteBackward(_ sender: Any?) {
        if self.selectedRange().length != 0 {
            ocdlDelegate?.deleteNode()
            ocdlDelegate?.refreshView()
        } else {
            print("need to select word explicitly")
        }
    }
    

    
}

protocol OCDLViewDelegate: AnyObject {
    func deleteNode()
    func refreshView()
}
