//
//  EditorView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import SwiftUI

import LanguageSupport
import CodeEditorView

struct EditorView: View {
    @State private var text:     String                    = "My awesome code..."
    @State private var position: CodeEditor.Position       = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    var body: some View {
        CodeEditor(text: $text, position: $position, messages: $messages, language: .swift())
            .environment(\.codeEditorTheme,
                          colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
    }
}
