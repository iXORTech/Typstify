//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import PDFKit
import SwiftUI
import TypstLibrarySwift

struct PDFKitView: UIViewRepresentable {
    var document: Data
    
    mutating func updateDocument(newDocument: Data) {
        document = newDocument
    }
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: document)
        return pdfView
    }
        
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) {
        // TODO
    }
}

struct ContentView: View {
    let source = """
#show math.equation: set text(font: "STIX Two Math")

= Hello, *world*!

This is from `Typst`.

```swift
print("Hello, world!")
```

$
B(P) = (mu_0)/(4pi) integral (I times hat(r)')/(r^('2)) d l = (mu_0)/(4pi) I integral (d l times hat(r)')/(r^('2))
$
"""
    
    var body: some View {
        let document = TypstLibrarySwift.getRenderedDocumentPdf(source: source)
        PDFKitView(document: document)
    }
}

#Preview {
    ContentView()
}
