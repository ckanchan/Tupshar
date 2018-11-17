//
//  AppDelegate.swift
//  Tupshar
//
//  Created by Chaitanya Kanchan on 25/03/2018.
//  Copyright © 2018 Chaitanya Kanchan. All rights reserved.
//

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

