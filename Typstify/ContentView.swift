//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import SwiftUI

import CodeEditorView
import LanguageSupport

struct ContentView: View {
    @State private var source:   String                    = "My awesome code..."
    @State private var position: CodeEditor.Position       = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    
    @FocusState private var editorIsFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            VStack {
                CodeEditor(text: $source, position: $position, messages: $messages, language: .swift())
                    .environment(\.codeEditorTheme,
                                  colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                    .focused($editorIsFocused)
            }
            .onAppear{ editorIsFocused =  true }
            
            DocumentView(source: $source)
        }
    }
}

#Preview {
    ContentView()
}
