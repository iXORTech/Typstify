//
//  DocumentView.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-07-28.
//

import SwiftUI

struct DocumentView: View {
    let document: Data
    
    var body: some View {
        PDFKitView(document: document)
    }
}
