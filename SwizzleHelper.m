//
//  SwizzleHelper.m
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

#import "SwizzleHelper.h"

// found here: https://github.com/defagos/CoconutKit/blob/master/Framework/Sources/Core/HLSRuntime.h 
#import "HLSRuntime.h"
#import <UIKit/UIKit.h>
#import <PDFKit/PDFKit.h>

static BOOL (*s_becomeFirstResponder)(id, SEL) = NULL;

static BOOL swizzle_becomeFirstResponder(id self, SEL _cmd)
{
    if ([self isKindOfClass:NSClassFromString(@"PDFDocumentView")]) {
        return NO;
    }
    return s_becomeFirstResponder(self, _cmd);
}

void SwizzlePDFDocumentView(void) {
    HLSSwizzleSelector([UIResponder class], @selector(becomeFirstResponder), swizzle_becomeFirstResponder, &s_becomeFirstResponder);
}
