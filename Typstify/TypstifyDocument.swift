//
//  TypstifyDocument.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-30.
//

import PDFKit
import SwiftUI
import UniformTypeIdentifiers

import TypstLibrarySwift

func renderTypstDocument(from source: String) throws -> PDFDocument? {
    let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
    return PDFDocument(data: document)
}

extension UTType {
    static var typstSource: UTType {
        UTType(importedAs: "public.typst-source")
    }
}

struct TypstifyDocument: FileDocument {
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    static var readableContentTypes: [UTType] { [.typstSource] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
