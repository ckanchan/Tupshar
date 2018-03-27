//
//  OCDLView.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 26/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

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
