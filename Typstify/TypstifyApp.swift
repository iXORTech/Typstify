//
//  TypstifyApp.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import SwiftUI

@main
struct TypstifyApp: App {
    // This is to prevent PDFView from stealing first responder when setting document.
    // See SwizzleHelper.h for more information.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        DocumentGroup(newDocument: TypstifyDocument()) { file in
            ContentView(
                document: file.$document,
                directory: file.fileURL?.deletingLastPathComponent()
            )
        }
    }
}
