//
//  DocumentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import SwiftUI

import TypstLibrarySwift

struct DocumentView: View {
    let source: String
    
    var body: some View {
        do {
            let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
            return PDFKitView(document: document)
        } catch let error as TypstCompilationError {
            return Text(error.message())
        } catch {
            return Text("An unknown error occurred.")
        }
    }
}
