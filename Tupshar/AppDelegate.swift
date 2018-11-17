//
//  AppDelegate.swift
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var cuneifier: LocalCuneifier = LocalCuneifier(withDictionary: [:])

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let ogslPath = Bundle.main.path(forResource: "ogsl", ofType: "json") else {return}
            guard let ogslData = try? Data(contentsOf: URL(fileURLWithPath: ogslPath)) else {return}
            guard let cuneifier = try? LocalCuneifier(json: ogslData) else {return}
            if let strongSelf = self {
                strongSelf.cuneifier = cuneifier
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    



}

