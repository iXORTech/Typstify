//
//  SwizzleHelper.h
//  Typstify
//
//  Created by Cubik65536 on 2024-08-04.
//

// This is to prevent PDFView from stealing first responder when setting document.
// https://gist.github.com/chbeer/5a4506d6e657c3b3ea3fdfd0391c9028

// I just migrated part of https://github.com/defagos/CoconutKit (the parts needed, HLSRuntime and HLSWeakObjectWrapper)
// to make this work. CoconutKit is distributed under MIT license.

// I know this is a very hacky workaround, but I don't have a better solution for now.
// If you do have a better solution, please do help me.

void SwizzlePDFDocumentView(void);
