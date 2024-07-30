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
                            messages.removeAll()
                            do {
                                try previewDocument = renderTypstDocument(from: source)
                            } catch let error as TypstCompilationError {
                                let diagnostics = error.diagnostics()
                                diagnostics.forEach { diagnostic in
                                    let line = diagnostic.lineStart
                                    let column = diagnostic.columnStart
                                    
                                    let category = switch diagnostic.severity {
                                    case SourceDiagnosticResultSeverity.error:
                                        Message.Category.error
                                    case SourceDiagnosticResultSeverity.warning:
                                        Message.Category.warning
                                    }
                                    
                                    let length = diagnostic.columnEnd - diagnostic.columnStart
                                    let summary = diagnostic.message
                                    
                                    messages.insert(
                                        TextLocated(
                                            location: TextLocation(oneBasedLine: Int(line), column: Int(column)),
                                            entity: Message(
                                                category: category,
                                                length: Int(length),
                                                summary: summary,
                                                description: NSAttributedString("")
                                            )
                                        )
                                    )
                                }
                                
                                previewDocument = nil
                            } catch {
                                messages.insert(
                                    TextLocated(
                                        location: TextLocation(oneBasedLine: 1, column: 1),
                                        entity: Message(
                                            category: Message.Category.error,
                                            length: 1,
                                            summary: "Unknown Error Occurred",
                                            description: NSAttributedString(
                                                "An unknown error prevented the compilation of the Typst Document"
                                            )
                                        )
                                    )
                                )
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
