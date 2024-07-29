//
//  PDFKitView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import PDFKit
import SwiftUI

import TypstLibrarySwift

struct DocumentView: UIViewRepresentable {
    @Binding var source: String
    
    func generateDocument() -> PDFDocument? {
        do {
            let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
            return PDFDocument(data: document)
        } catch _ as TypstCompilationError {
            return nil
        } catch {
            return nil
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<DocumentView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = generateDocument()
        return pdfView
    }
        
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<DocumentView>) {
        uiView.document = generateDocument()
    }
}
