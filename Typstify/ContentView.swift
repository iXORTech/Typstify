//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import PDFKit
import SwiftUI

import CodeEditorView
import LanguageSupport
import TypstLibrarySwift

func renderTypstDocument(from source: String) throws -> PDFDocument? {
    let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
    return PDFDocument(data: document)
}

struct ContentView: View {
    @State private var source:          String                      = ""
    @State private var position:        CodeEditor.Position         = CodeEditor.Position()
    @State private var messages:        Set<TextLocated<Message>>   = Set()
    @State private var previewDocument: PDFDocument?                = nil
    
    @State private var showSource:      Bool              = true
    @State private var showPreview:     Bool              = true
    @State private var theme:           ColorScheme?      = nil
    @State private var showMinimap:     Bool              = true
    @State private var wrapText:        Bool              = true
    
    @FocusState private var editorIsFocused: Bool
    @FocusState private var documentIsFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Toggle("Show Source", systemImage: "doc.plaintext", isOn: $showSource.animation())
#if os(macOS)
                    .toggleStyle(.checkbox)
#else
                    .toggleStyle(.button)
                    .labelStyle(.iconOnly)
#endif
                
                Toggle("Show Preview", systemImage: "sidebar.squares.right", isOn: $showPreview.animation(
                    .linear
                ))
#if os(macOS)
                    .toggleStyle(.checkbox)
#else
                    .toggleStyle(.button)
                    .labelStyle(.iconOnly)
#endif
            }
            .padding()
            
            HStack {
                if showSource {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Toggle("Minimap", systemImage: "chart.bar.doc.horizontal", isOn: $showMinimap)
#if os(macOS)
                                .toggleStyle(.checkbox)
#else
                                .toggleStyle(.button)
                                .labelStyle(.iconOnly)
                                .tint(Color.gray)
                            
                                .dynamicTypeSize(DynamicTypeSize.small)
#endif
                        }
                        
                        CodeEditor(
                            text: $source,
                            position: $position,
                            messages: $messages,
                            language: .swift(),
                            layout: CodeEditor.LayoutConfiguration(showMinimap: showMinimap, wrapText: wrapText)
                        )
                        .environment(\.codeEditorTheme,
                                      colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                        .focused($editorIsFocused)
                        .onChange(of: source, {
                            do {
                                try previewDocument = renderTypstDocument(from: source)
                            } catch {
                                print("Error rendering document: \(error)")
                                previewDocument = nil
                            }
                        })
                    }
                }
                
                if showPreview {
                    DocumentView(document: $previewDocument)
                        .focused($documentIsFocused)
                        .onChange(of: documentIsFocused, {
                            editorIsFocused = true
                        })
                }
            }
            .onAppear{ editorIsFocused =  true }
        }
    }
}

#Preview {
    ContentView()
}
