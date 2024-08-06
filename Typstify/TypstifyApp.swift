//
//  TypstifyApp.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import SwiftUI

@Observable
final class TypstifyModel {
    var name:     String
    var document: TypstifyDocument
    
    init(name: String, document: TypstifyDocument) {
        self.name       = name
        self.document   = document
    }
}

@main
struct TypstifyApp: App {
    // This is to prevent PDFView from stealing first responder when setting document.
    // See SwizzleHelper.h for more information.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var navigatorDemoModel = TypstifyModel(name: "", document: TypstifyDocument())
    
    var body: some Scene {
        DocumentGroup(newDocument: { TypstifyDocument() }) { file in
            ContentView(
                projectURL: file.fileURL
            )
            .environment(navigatorDemoModel)
            .onAppear {
                navigatorDemoModel.name     = file.fileURL?.lastPathComponent ?? "Untitled"
                navigatorDemoModel.document = file.document
            }
        }
    }
}
