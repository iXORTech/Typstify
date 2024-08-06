//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import Files
import PDFKit
import PhotosUI
import SwiftUI

import CodeEditorView
import LanguageSupport
import ProjectNavigator
import TypstLibrarySwift

// MARK: -
// MARK: UUID serialisation

extension UUID: @retroactive RawRepresentable {
    public var rawValue: String { uuidString }
    
    public init?(rawValue: String) {
        self.init(uuidString: rawValue)
    }
}

// MARK: -
// MARK: Views

struct DocumentView: View {
    var projectURL: URL?
    
    @Binding var source:             String
    @Binding var showSource:         Bool
    @Binding var showPreview:        Bool
    @Binding var insertingPhotoItem: PhotosPickerItem?
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @State private var position:        CodeEditor.Position         = CodeEditor.Position()
    @State private var messages:        Set<TextLocated<Message>>   = Set()
    @State private var previewDocument: PDFDocument?                = nil
    
    @State private var theme:           ColorScheme?      = nil
    @State private var showMinimap:     Bool              = true
    @State private var wrapText:        Bool              = true
    
    func updatePreview(source: String) {
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
    }
    
    var body: some View {
        HStack {
            if showSource {
                VStack {
                    HStack {
                        Spacer()
                        
                        Toggle("Minimap", systemImage: "chart.bar.doc.horizontal", isOn: $showMinimap)
                            .toggleStyle(.button)
                            .labelStyle(.iconOnly)
                            .tint(Color.gray)
                            .dynamicTypeSize(DynamicTypeSize.small)
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
                }
            }
            
            if showPreview {
                TypstifyDocumentView(document: $previewDocument)
            }
        }
        .onChange(of: source, {
            updatePreview(source: source)
        })
        .onAppear {
            updatePreview(source: source)
        }
        .onChange(of: insertingPhotoItem) {
            Task {
                insertingPhotoItem?.writeToDirectory(
                    directory: projectURL!,
                    completionHandler: {  result in
                        switch result {
                        case .success(let url):
                            let imageName = url.lastPathComponent
                            DispatchQueue.main.async {
                                source.append("""
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
    }
}

struct FileContextMenu: View {
    let cursor: FileNavigatorCursor<Payload>
    
    @Binding var editedText: String?
    
    let proxy:       File<Payload>.Proxy
    let viewContext: ViewContext
    
    var body: some View {
        Button {
            editedText = cursor.name
        } label: {
            Label("Change name", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            withAnimation {
                viewContext.remove(cursor: cursor)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
        
    }
}

struct FolderContextMenu: View {
    let cursor: FileNavigatorCursor<Payload>
    
    @Binding var editedText: String?
    @Binding var folder:     ProxyFolder<Payload>
    
    let viewContext: ViewContext
    
    var body: some View {
        Button {
            withAnimation {
                viewContext.add(item: FileOrFolder(file: File(contents: Payload(text: ""))),
                                $to: $folder,
                                withPreferredName: "untitled.typ")
            }
        } label: {
            Label("New file", systemImage: "doc.badge.plus")
        }
        
        Button {
            withAnimation {
                viewContext.add(item: FileOrFolder(folder: Folder(children: [:])), $to: $folder, withPreferredName: "Folder")
            }
        } label: {
            Label("New folder", systemImage: "folder.badge.plus")
        }
        
        // Only support rename and delete action if this menu doesn't apply to the root folder
        if cursor.parent.wrappedValue != nil {
            Divider()
            
            Button {
                editedText = cursor.name
            } label: {
                Label("Change name", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                withAnimation {
                    viewContext.remove(cursor: cursor)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct Navigator: View {
    var projectURL: URL?
    
    @Bindable var viewState: FileNavigatorViewState
    
    @Binding var columnVisibility:    NavigationSplitViewVisibility
    @Binding var showSource:          Bool
    @Binding var showPreview:         Bool
    @Binding var insertingPhotoItem:  PhotosPickerItem?
    
    @Environment(TypstifyModel.self) private var model: TypstifyModel
    @Environment(\.undoManager) var undoManager: UndoManager?
    
    @State private var selected: FileOrFolder.ID?
    @State private var showDetail: Bool = false
    
    var body: some View {
        @Bindable var model = model
        let viewContext = ViewContext(viewState: viewState, model: model, undoManager: undoManager)
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $viewState.selection) {
                FileNavigator(name: model.name,
                              item: $model.document.texts.root,
                              parent: .constant(nil),
                              viewState: viewState)
                { cursor, $editedText, proxy in
                    
                    EditableLabel(cursor.name, systemImage: "doc.plaintext.fill", editedText: $editedText)
                        .onSubmit{ viewContext.rename(cursor: cursor, $to: $editedText) }
                        .contextMenu{ FileContextMenu(cursor: cursor,
                                                      editedText: $editedText,
                                                      proxy: proxy,
                                                      viewContext: viewContext) }
                    
                } folderLabel: { cursor, $editedText, $folder in
                    
                    EditableLabel(cursor.name, systemImage: "folder.fill", editedText: $editedText)
                        .onSubmit{ viewContext.rename(cursor: cursor, $to: $editedText) }
                        .contextMenu{ FolderContextMenu(cursor: cursor,
                                                        editedText: $editedText,
                                                        folder: $folder,
                                                        viewContext: viewContext) }
                    
                }
                .navigatorFilter{ $0.first != Character(".") }
            }
            .listStyle(.sidebar)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if showDetail {
                if let uuid = selected,
                   let $file = Binding(unwrap: model.document.texts.proxy(for: uuid).binding) {
                    if let $text = Binding($file.contents.text) {
                        DocumentView(
                            projectURL: projectURL,
                            source: $text,
                            showSource: $showSource,
                            showPreview: $showPreview,
                            insertingPhotoItem: $insertingPhotoItem
                        )
                        .toolbar(.hidden, for: .navigationBar)
                        .toolbar(removing: .sidebarToggle)
                    } else { Text("Not a UTF-8 text file") }
                } else { Text("Select a file") }
            }
        }
        .onChange(of: viewState.selection, {
            showDetail = false;
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5)) {
                selected = viewState.selection
                showDetail = true;
            }
        })
        .onChange(of: insertingPhotoItem, {
            
        })
    }
}

/// This is the toplevel content view. It expects the app model as the environment object.
struct ContentView: View {
    var projectURL: URL?
    
    @SceneStorage("navigatorExpansions") private var expansions: WrappedUUIDSet?
    @SceneStorage("navigatorSelection")  private var selection:  FileOrFolder.ID?
    
    @State private var fileNavigationViewState = FileNavigatorViewState()
    
    @State private var columnVisibility:    NavigationSplitViewVisibility   = NavigationSplitViewVisibility.all
    @State private var showSource:          Bool                            = true
    @State private var showPreview:         Bool                            = true
    @State private var insertingPhotoItem:  PhotosPickerItem?
    
    var body: some View {
        Navigator(
            projectURL: projectURL,
            viewState: fileNavigationViewState,
            columnVisibility: $columnVisibility,
            showSource: $showSource,
            showPreview: $showPreview,
            insertingPhotoItem: $insertingPhotoItem
        )
        .onAppear {
            if let savedExpansions = expansions {
                fileNavigationViewState.expansions = savedExpansions
            }
        }
        .onChange(of: fileNavigationViewState.expansions) {
            expansions = fileNavigationViewState.expansions
        }
        .onAppear {
            print("documents directory: \(URL.documentsDirectory)")
            print("file url: \(String(describing: projectURL?.path()))")
            
            if projectURL != nil {
                do {
                    try TypstLibrarySwift.setWorkingDirectory(path: (
                        projectURL?.path()
                    )!)
                } catch {
                    print("Failed to set working directory. Error: \(error)")
                }
            }
            
            if let savedSelection = selection {
                fileNavigationViewState.selection = savedSelection
            }
        }
        .onChange(of: fileNavigationViewState.selection) {
            selection = fileNavigationViewState.selection
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button(action: {
                    if columnVisibility == .all {
                        columnVisibility = .detailOnly
                    } else {
                        columnVisibility = .all
                    }
                }, label: {
                    Label("Show File Navigator", systemImage: "sidebar.left")
                        .labelStyle(.iconOnly)
                })
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(selection: $insertingPhotoItem, label: {
                    Label("Insert Image", systemImage: "photo.badge.plus")
                })
                
                Spacer()
                
                Toggle("Show Source", systemImage: "text.word.spacing", isOn: $showSource.animation())
                    .toggleStyle(.button)
                    .labelStyle(.iconOnly)
                
                Toggle("Show Preview", systemImage: "sidebar.right", isOn: $showPreview.animation(
                    .linear
                ))
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
            }
        })
    }
}


// MARK: -
// MARK: Preview

struct ContentView_Previews: PreviewProvider {
    struct Container: View {
        let document = TypstifyDocument(text: "Hello, World!")
        
        var body: some View {
            ContentView()
                .environment(TypstifyModel(name: "Preview", document: document))
        }
    }
    
    static var previews: some View {
        Container()
    }
}
