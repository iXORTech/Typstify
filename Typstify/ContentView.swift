//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import PDFKit
import PhotosUI
import SwiftUI

import CodeEditorView
import LanguageSupport
import TypstLibrarySwift

struct ContentView: View {
    @Binding var document: TypstifyDocument
    var directory: URL?
    
    @State private var position:        CodeEditor.Position         = CodeEditor.Position()
    @State private var messages:        Set<TextLocated<Message>>   = Set()
    @State private var previewDocument: PDFDocument?                = nil
    
    @State private var insertingPhotoItem: PhotosPickerItem?
    
    @State private var showSource:      Bool              = true
    @State private var showPreview:     Bool              = true
    @State private var theme:           ColorScheme?      = nil
    @State private var showMinimap:     Bool              = true
    @State private var wrapText:        Bool              = true
    
    @FocusState private var editorIsFocused: Bool
    @FocusState private var documentIsFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    func updatePreview() {
        messages.removeAll()
        do {
            try previewDocument = renderTypstDocument(from: document.text)
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
    }
    
    var body: some View {
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
                        text: $document.text,
                        position: $position,
                        messages: $messages,
                        language: .swift(),
                        layout: CodeEditor.LayoutConfiguration(showMinimap: showMinimap, wrapText: wrapText)
                    )
                    .environment(\.codeEditorTheme,
                                  colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                    .focused($editorIsFocused)
                    .onChange(of: document.text, {
                        updatePreview()
                    })
                }
            }
            
            if showPreview {
                TypstifyDocumentView(document: $previewDocument)
            }
        }
        .onAppear {
            print("documents directory: \(URL.documentsDirectory)")
            print("file directory: \(String(describing: directory?.path()))")
            
            if directory != nil {
                do {
                    try TypstLibrarySwift.setWorkingDirectory(path: (
                        directory?.path()
                    )!)
                } catch {
                    print("Failed to set working directory. Error: \(error)")
                }
            }
            
            editorIsFocused = true
            updatePreview()
        }
        .onChange(of: insertingPhotoItem) {
            Task {
                insertingPhotoItem?.writeToDirectory(
                    directory: directory!,
                    completionHandler: {  result in
                        switch result {
                        case .success(let url):
                            let imageName = url.lastPathComponent
                            DispatchQueue.main.async {
                                document.text.append("""
#figure(
    image("\(imageName)"),
    caption: [],
)
""")
                            }
                        case .failure(let failure):
                            print(failure.localizedDescription)
                        }
                    })
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(selection: $insertingPhotoItem, label: {
                    Label("Insert Image", systemImage: "photo.badge.plus")
                })
                
                Spacer()
                
                Toggle("Show Source", systemImage: "text.word.spacing", isOn: $showSource.animation())
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
        })
    }
}

#Preview {
    ContentView(document: .constant(TypstifyDocument(text: "Hello, World from `Typst`!")))
}
