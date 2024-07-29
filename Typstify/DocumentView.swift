//
//  PDFKitView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import PDFKit
import SwiftUI

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
    @Binding var document: PDFDocument?
    
    func makeUIView(context: UIViewRepresentableContext<DocumentView>) -> NonFocusablePDFView {
        let pdfView = NonFocusablePDFView()
        pdfView.document = document
        return pdfView
    }
    
    func updateUIView(_ uiView: NonFocusablePDFView, context: UIViewRepresentableContext<DocumentView>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.document = document
        }
    }
}
