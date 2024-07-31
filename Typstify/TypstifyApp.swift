//
//  TypstifyApp.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import SwiftUI

@main
struct TypstifyApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TypstifyDocument()) { file in
            ContentView(
                document: file.$document,
                directory: file.fileURL?.deletingLastPathComponent()
            )
        }
    }
}
