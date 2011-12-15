//
//  AXImageFetchRequestStack.h
//  AXKit
//
//  Created by James Savage on 12/12/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "AXImageFetchRequest.h"

@interface AXImageFetchRequestStack : NSObject

- (id)initWithStackSize:(NSUInteger)stackSize;
- (id)initWithStackSize:(NSUInteger)stackSize
 maxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads;

- (void)fetchImageAtURL:(NSURL *)url
      stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock;

- (void)fetchImageAtURL:(NSURL *)url
          progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
      stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock;

@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, readonly) NSUInteger pendingDownloadsCount;
@property (nonatomic) NSUInteger stackSize;
@property (nonatomic) NSUInteger maxConcurrentDownloads;

@end
