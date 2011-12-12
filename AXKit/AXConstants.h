//
//  AXConstants.h
//  AXKit
//
//  Created by James Savage on 12/9/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

extern NSString * const kAXErrorDomain;

#define AX_DispatchAsyncOnQueue(queue, block, ...) \
    if (block != NULL) dispatch_async(queue, ^{ block(__VA_ARGS__); })

#define AX_DispatchSyncOnQueue(queue, block, ...) \
    if (block != NULL) if (dispatch_get_current_queue() == queue) block(__VA_ARGS__); else dispatch_sync(queue, ^{ block(__VA_ARGS__); })