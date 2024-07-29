//
//  PDFKitView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    var document: Data
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: document)
        return pdfView
    }
        
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) {
        uiView.document = PDFDocument(data: document)
    }
}
