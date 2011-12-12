//
//  AXImageFetchRequestStack.m
//  AXKit
//
//  Created by James Savage on 12/12/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "AXImageFetchRequestStack.h"

@interface AXImageFetchRequestStack ()
- (void)pokeDownloadStack;
@end

@implementation AXImageFetchRequestStack {
    NSMutableArray * _downloadsStack;
}

@synthesize callbackQueue = _callbackQueue;
@synthesize stackSize = _stackSize;

- (id)init
{
    return [self initWithStackSize:10];
}

- (id)initWithStackSize:(NSUInteger)stackSize
{
    if ((self = [super init])) {
        
        _stackSize = stackSize;
    }
    
    return self;
}

@end
