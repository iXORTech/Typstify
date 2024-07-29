//
//  PDFKitView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import PDFKit
import SwiftUI

import TypstLibrarySwift

class NonFocusablePDFView: PDFView {
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override var canBecomeFirstResponder: Bool {
        false
    }
    
    override var canBecomeFocused: Bool {
        false
    }
}

struct DocumentView: UIViewRepresentable {
    @Binding var source: String
    
    func generateDocument(from source: String) -> PDFDocument? {
        do {
            let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
            return PDFDocument(data: document)
        } catch _ as TypstCompilationError {
            return nil
        } catch {
            return nil
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<DocumentView>) -> NonFocusablePDFView {
        let pdfView = NonFocusablePDFView()
        pdfView.document = generateDocument(from: source)
        return pdfView
    }
    
    func updateUIView(_ uiView: NonFocusablePDFView, context: UIViewRepresentableContext<DocumentView>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.document = generateDocument(from: source)
        }
    }
}
