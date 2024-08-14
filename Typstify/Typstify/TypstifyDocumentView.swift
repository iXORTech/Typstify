//
//  PDFKitView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import PDFKit
import SwiftUI

struct TypstifyDocumentView: UIViewRepresentable {
    @Binding var document: PDFDocument?
    
    func makeUIView(context: UIViewRepresentableContext<TypstifyDocumentView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<TypstifyDocumentView>) {
        uiView.document = document
    }
}
