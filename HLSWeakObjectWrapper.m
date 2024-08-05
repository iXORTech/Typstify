//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  Originally from https://github.com/defagos/CoconutKit, distributed under MIT license.
//

#import "HLSWeakObjectWrapper.h"

@interface HLSWeakObjectWrapper ()

@property (nonatomic, weak) id object;

@end

@implementation HLSWeakObjectWrapper

- (instancetype)initWithObject:(id)object
{
    if (self = [super init]) {
        self.object = object;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithObject:nil];
}

@end
