//
//  InfoViewController.swift
//  Tupshar: novelty cuneiform text editor
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

import Cocoa
import CDKSwiftOracc

class InfoViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var titleBox: NSTextField!
    @IBOutlet weak var shortNameBox: NSTextField!
    @IBOutlet weak var authorBox: NSTextField!
    @IBOutlet weak var projectBox: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        [titleBox, shortNameBox, authorBox, projectBox].forEach{ input in input.delegate = self }
    }
    
    override func viewWillAppear() {
        titleBox.stringValue = document.metadata.title
        shortNameBox.stringValue = document.metadata.displayName
        authorBox.stringValue = document.metadata.ancientAuthor ?? ""
        projectBox.stringValue = document.metadata.project
    }
 
    func controlTextDidEndEditing(_ obj: Notification) {
        let textBox = obj.object! as! NSTextField
        switch textBox {
        case self.titleBox:
            document.metadata.title = textBox.stringValue
        case shortNameBox:
            document.metadata.displayName = textBox.stringValue
        case authorBox:
            document.metadata.ancientAuthor = textBox.stringValue
        case projectBox:
            document.metadata.project = textBox.stringValue
        default:
            return
        }
    }
    
}
