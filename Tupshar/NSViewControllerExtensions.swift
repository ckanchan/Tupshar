//
//  NSViewControllerExtensions.swift
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

import Cocoa
import CDKSwiftOracc

extension NSViewController {
    var document: Document {
        let document = view.window?.windowController?.document as? Document ?? self.parent?.view.window?.windowController?.document as? Document
        assert(document != nil, "Unable to find document for viewcontroller")
        return document!
    }
    
    var cuneifier: Cuneifier {
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        return delegate.cuneifier
    }
}
