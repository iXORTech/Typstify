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

import ProjectNavigator
import STTextViewSwiftUI

typealias Font = UIFont
typealias Color = UIColor
let textColor = Color.label

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
    @Binding var insertingPhotoPath: Set<String>
    
    @State private var editor: AttributedString = ""
    @State private var selection: NSRange?
    @State private var counter = 0
    @State private var font = Font.monospacedSystemFont(ofSize: 0, weight: .medium)
    @State private var previewDocument: PDFDocument?                = nil
    
    
    func updatePreview(source: String) {
        do {
            try previewDocument = renderTypstDocument(from: source)
        } catch let error as TypstCompilationError {
            previewDocument = nil
        } catch {
            previewDocument = nil
        }
    }
    
    var body: some View {
        HStack {
            if showSource {
                VStack {
                    TextView(
                        text: $editor,
                        selection: $selection,
                        options: [.wrapLines, .highlightSelectedLine, .showLineNumbers]
                    )
                    .textViewFont(font)
                    .onChange(of: editor, {
                        source = String(editor.characters)
                    })
                    
                    HStack {
                        if let selection {
                            Text("Location: \(selection.location)")
                        } else {
                            Text("No selection")
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            if showPreview {
                TypstifyDocumentView(document: $previewDocument)
            }
        }
        .onChange(of: source, {
            updatePreview(source: source)
            self.editor = AttributedString(
                source,
                attributes: AttributeContainer([.foregroundColor: textColor, .font: font])
            )
        })
        .onAppear {
            updatePreview(source: source)
            self.editor = AttributedString(
                source,
                attributes: AttributeContainer([.foregroundColor: textColor, .font: font])
            )
        }
        .onChange(of: insertingPhotoPath) {
            DispatchQueue.main.async {
                for path in insertingPhotoPath {
                    source.append("""
                        #figure(
                            image("\(path)"),
                            caption: [],
                        )
                        """)
                }
                insertingPhotoPath.removeAll()
            }
            self.editor = AttributedString(
                source,
                attributes: AttributeContainer([.foregroundColor: textColor, .font: font])
            )
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
            Label("Rename", systemImage: "pencil")
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
    
    @Binding var newFileFolderName: String
    @Binding var showingNewTypstSourceAlert: Bool
    @Binding var showingNewFolderAlert: Bool
    
    let viewContext: ViewContext
    
    var body: some View {
        Button {
            newFileFolderName = ""
            showingNewTypstSourceAlert = true
        } label: {
            Label("New Typst Source", systemImage: "doc.badge.plus")
        }
        
        Button {
            newFileFolderName = ""
            showingNewFolderAlert = true
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }
        
        // Only support rename and delete action if this menu doesn't apply to the root folder
        if cursor.parent.wrappedValue != nil {
            Divider()
            
            Button {
                editedText = cursor.name
            } label: {
                Label("Rename", systemImage: "pencil")
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
    
    @Bindable var viewState: FileNavigatorViewState<Payload>
    
    @Binding var columnVisibility:    NavigationSplitViewVisibility
    @Binding var documentOpen:        Bool
    @Binding var showSource:          Bool
    @Binding var showPreview:         Bool
    @Binding var insertingPhotoItem:  PhotosPickerItem?
    
    @Environment(TypstifyModel.self) private var model: TypstifyModel
    @Environment(\.undoManager) var undoManager: UndoManager?
    
    @State private var changeByUndoManager: Bool = false
    
    @State private var selected: FileOrFolder.ID?
    @State private var showDetail: Bool = false
    @State private var insertingPhotoPath: Set<String> = Set()
    
    @State private var newFileFolderName: String = ""
    @State private var showingNewTypstSourceAlert: Bool = false
    @State private var showingNewFolderAlert: Bool = false
    
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
                        .alert("Enter File Name", isPresented: $showingNewTypstSourceAlert) {
                            TextField("untitled", text: $newFileFolderName)
                            Button("OK") {
                                withAnimation {
                                    if newFileFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        newFileFolderName = "untitled"
                                    }
                                    viewContext.add(item: FileOrFolder(file: File(contents: Payload(text: ""))),
                                                    $to: $folder,
                                                    withPreferredName: "\(newFileFolderName).typ")
                                }
                            }
                        }
                        .alert("Enter Folder Name", isPresented: $showingNewFolderAlert) {
                            TextField("Folder", text: $newFileFolderName)
                            Button("OK") {
                                withAnimation {
                                    if newFileFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        newFileFolderName = "Folder"
                                    }
                                    viewContext.add(item: FileOrFolder(folder: Folder(children: [:])), $to: $folder, withPreferredName: "\(newFileFolderName)")
                                }
                            }
                        }
                        .onSubmit{ viewContext.rename(cursor: cursor, $to: $editedText) }
                        .contextMenu{ FolderContextMenu(cursor: cursor,
                                                        editedText: $editedText,
                                                        folder: $folder,
                                                        newFileFolderName: $newFileFolderName,
                                                        showingNewTypstSourceAlert: $showingNewTypstSourceAlert,
                                                        showingNewFolderAlert: $showingNewFolderAlert,
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
                            insertingPhotoPath: $insertingPhotoPath
                        )
                        .onAppear(perform: {
                            documentOpen = true
                        })
                        .toolbar(.hidden, for: .navigationBar)
                        .toolbar(removing: .sidebarToggle)
                        .onChange(of: $text.wrappedValue) { (oldValue, newValue) in
                            guard !changeByUndoManager else {
                                changeByUndoManager = false
                                return
                            }
                            
#if os(iOS) || os(visionOS)
                            undoManager?.registerUndo(withTarget: model) { [weak undoManager] _ in
                                $text.wrappedValue = oldValue
                                changeByUndoManager =  true
                                undoManager?.registerUndo(withTarget: model) { _ in
                                    $text.wrappedValue = newValue
                                    changeByUndoManager =  true
                                }
                            }
#endif
                        }
                        .onChange(of: insertingPhotoItem, {
                            insertingPhotoItem?.getData(completionHandler: { result in
                                switch result {
                                case .success(let data):
                                    insertingPhotoItem?.getFilename(completionHandler: { result in
                                        switch result {
                                        case .success(let name):
                                            var dir = projectURL
                                            if let dominantFolder = viewState.dominantFolder {
                                                if let foler = dominantFolder.wrappedValue {
                                                    let folderPath = model.document.texts.filePath(of: foler.id).string
                                                    if !folderPath.isEmpty {
                                                        dir = projectURL?.appendingPathComponent(folderPath)
                                                    }
                                                }
                                            }
                                            
                                            do {
                                                try viewContext.add(
                                                    item: FileOrFolder(
                                                        file: File(contents: Payload(name: name, data: data))
                                                    ),
                                                    $to: viewState.dominantFolder!,
                                                    withPreferredName: "\(name)"
                                                )
                                                
                                                var isDirectory: ObjCBool = true
                                                if !FileManager.default.fileExists(atPath: dir?.path() ?? "", isDirectory: &isDirectory) {
                                                    if let directory = dir {
                                                        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                                                    }
                                                }
                                                
                                                let fullPath = dir?.appendingPathComponent(name).path()
                                                try data.write(to: URL(fileURLWithPath: fullPath ?? ""))
                                                insertingPhotoPath.insert(name)
                                            } catch {
                                                print("Image Insertion Error: \(error)")
                                            }
                                        case .failure(let failure):
                                            print(failure.localizedDescription)
                                        }
                                    })
                                case .failure(let failure):
                                    print(failure.localizedDescription)
                                }
                            })
                        })
                    } else {
                        Text("Not a UTF-8 text file")
                            .onAppear(perform: {
                                documentOpen = false
                            })
                    }
                } else {
                    Text("Select a file")
                        .onAppear(perform: {
                            documentOpen = false
                        })
                }
            }
        }
        .onChange(of: viewState.selection, {
            showDetail = false;
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5)) {
                selected = viewState.selection
                showDetail = true;
            }
            
            if projectURL != nil {
                if let dominantFolder = viewState.dominantFolder {
                    if let foler = dominantFolder.wrappedValue {
                        let folderPath = model.document.texts.filePath(of: foler.id).string
                        do {
                            if folderPath.isEmpty {
                                try set_working_directory((projectURL?.path())!)
                            } else {
                                print("Setting working directory to: \((projectURL?.appendingPathComponent(folderPath).path())!)")
                                try set_working_directory((projectURL?.appendingPathComponent(folderPath).path())!)
                            }
                        } catch {
                            print("Failed to set working directory. Error: \(error)")
                        }
                    }
                }
            }
        })
    }
}

/// This is the toplevel content view. It expects the app model as the environment object.
struct ContentView: View {
    var projectURL: URL?
    
    @SceneStorage("navigatorExpansions") private var expansions: WrappedUUIDSet?
    @SceneStorage("navigatorSelection")  private var selection:  FileOrFolder.ID?
    
    @State private var fileNavigationViewState = FileNavigatorViewState<Payload>()
    
    @State private var columnVisibility:    NavigationSplitViewVisibility   = NavigationSplitViewVisibility.all
    @State private var documentOpen:        Bool                            = false
    @State private var showSource:          Bool                            = true
    @State private var showPreview:         Bool                            = true
    @State private var insertingPhotoItem:  PhotosPickerItem?
    
    var body: some View {
        Navigator(
            projectURL: projectURL,
            viewState: fileNavigationViewState,
            columnVisibility: $columnVisibility,
            documentOpen: $documentOpen,
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
                }).disabled(!documentOpen)
                
                Spacer()
                
                Toggle("Show Source", systemImage: "text.word.spacing", isOn: $showSource.animation())
                    .toggleStyle(.button)
                    .labelStyle(.iconOnly)
                    .disabled(!documentOpen)
                
                Toggle("Show Preview", systemImage: "sidebar.right", isOn: $showPreview.animation(
                    .linear
                ))
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
                .disabled(!documentOpen)
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
