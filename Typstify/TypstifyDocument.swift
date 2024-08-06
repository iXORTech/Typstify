//
//  TypstifyDocument.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-30.
//

import Files
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import Observation
import os

import TypstLibrarySwift

private let logger = Logger(subsystem: "dev.ixor.Typstify", category: "Typstify")

private let fileMapName = ".FileMap.plist"

extension UTType {
    static let typstifyProject: UTType = UTType(exportedAs: "dev.ixor.typstify-project")
}

func renderTypstDocument(from source: String) throws -> PDFDocument? {
    let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
    return PDFDocument(data: document)
}

// MARK: -
// MARK: Payload

struct Payload: FileContents {
    /// Text in a file if its a text file containing UTF-8.
    var text: String? {
        didSet {
            backingData = nil
        }
    }
    
    /// Data in a file unless `text` has been updated and not yet marshalled back to `Data` again.
    private var backingData: Data?
    
    init(text: String) {
        self.text = text
    }
    
    /// Files ending with a text file extension are converted to text if they conform to UTF-8.
    init(name: String, data: Data) throws {
        self.backingData = data
        if UTType(filenameExtension: (name as NSString).pathExtension, conformingTo: .text) != nil,
           let text = String(data: data, encoding: .utf8) {
            self.text = text
        }
    }
    
    func data() throws -> Data {
        if let data = backingData { return data }
        else if let data = text?.data(using: .utf8) { return data }
        else { throw CocoaError(.formatting) }
    }
    
    /// Update backing data if necessary.
    mutating func flush() {
        if backingData == nil,
           let data = text?.data(using: .utf8)
        {
            backingData = data
        }
    }
}


// MARK: -
// MARK: Document

@Observable
final class TypstifyDocument: ReferenceFileDocument {
    typealias Snapshot = FullFileOrFolder<Payload>
    
    var texts: FileTree<Payload>
    
    static var readableContentTypes: [UTType] { [.typstifyProject] }
    
    init() {
        self.texts = FileTree(files: FullFileOrFolder(folder: FullFolder(children: [:])))
    }
    
    init(text: String) {
        let folder = FullFolder(children: ["main.typ": FileOrFolder(file: File(contents: Payload(text: text)))])
        self.texts = FileTree(files: FullFileOrFolder(folder: folder))
    }
    
    init(configuration: ReadConfiguration) throws {
        guard configuration.file.isDirectory,
              let fileWrappers = configuration.file.fileWrappers
        else {
            logger.error("Couldn't get directory file wrapper")
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Get the persistent file ids if available.
        let fileMap: FileIDMap?
        if let fileMapFileWrapper = fileWrappers[fileMapName],
           fileMapFileWrapper.isRegularFile,
           let fileMapData = fileMapFileWrapper.regularFileContents
        {
            
            let decoder = PropertyListDecoder()
            fileMap = try? decoder.decode(FileIDMap.self, from: fileMapData)
            
        } else { fileMap = nil }
        
        // Slurp in the tree of folders.
        let folder = try FullFolder<Payload>(fileWrappers: fileWrappers, persistentIDMap: fileMap)
        texts = FileTree(files: FullFileOrFolder(folder: folder))
    }
    
    func snapshot(contentType: UTType) throws -> Snapshot {
        // TODO: On iOS, we don't get passed the correct declared content type for some reason
        if contentType != .typstifyProject {
            logger.error("Snapshot of unknown content type: identifier = '\(contentType.identifier)'")
        }
        
        return try texts.snapshot()
    }
    
    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let fileWrapper = try snapshot.fileWrapper()
        if fileWrapper.isDirectory {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let newFileMapData = try encoder.encode(texts.fileIDMap)
            
            if let fileMapWrapper = fileWrapper.fileWrappers?[fileMapName] {
                // If the file map wrapper is already up to date, don't make any further changes
                if fileMapWrapper.isRegularFile && fileMapWrapper.regularFileContents == newFileMapData {
                    return fileWrapper
                }
                fileWrapper.removeFileWrapper(fileMapWrapper)
            }
            fileWrapper.addRegularFile(withContents: newFileMapData, preferredFilename: fileMapName)
        }
        return fileWrapper
    }
}
