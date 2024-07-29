//
//  ContentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-27.
//

import SwiftUI
import TypstLibrarySwift

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

$
E = mc^2
$
"""
    
    var body: some View {
        do {
            let document = try TypstLibrarySwift.getRenderedDocumentPdf(source: source)
            return DocumentView(document: document)
        } catch let error as TypstCompilationError {
            return Text(error.message())
        } catch {
            return Text("An unknown error occurred.")
        }
    }
}

#Preview {
    ContentView()
}
