//
//  AXImageFetchRequestStack.m
//  AXKit
//
//  Created by James Savage on 12/12/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "AXImageFetchRequestStack.h"
#import "AXImageFetchRequest.h"

#define AX_DEFAULT_STACK_SIZE 10
#define AX_DEFAULT_MAX_CONCURRENT_DOWNLOADS 1

@interface AXImageFetchRequestStack () {
    // This will serve as the "stack". New items go at the end
    // and extras are popped off the front.
    NSMutableArray * _downloadStack;
    NSMutableSet * _activeRequests;
    
    dispatch_queue_t _originQueue;
}

- (void)completedActiveRequest:(AXImageFetchRequest *)request;
- (void)pokeDownloadStack;
@end

@implementation AXImageFetchRequestStack

@synthesize callbackQueue = _callbackQueue;
@synthesize stackSize = _stackSize;
@synthesize maxConcurrentDownloads = _maxConcurrentDownloads;

- (id)init
{
    return [self initWithStackSize:AX_DEFAULT_STACK_SIZE maxConcurrentDownloads:AX_DEFAULT_MAX_CONCURRENT_DOWNLOADS];
}

- (id)initWithStackSize:(NSUInteger)stackSize
{
    return [self initWithStackSize:stackSize maxConcurrentDownloads:AX_DEFAULT_MAX_CONCURRENT_DOWNLOADS];
}

- (id)initWithStackSize:(NSUInteger)stackSize
 maxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads
{
    if ((self = [super init])) {
        _stackSize = stackSize;
        _maxConcurrentDownloads = maxConcurrentDownloads;
        _downloadStack = [[NSMutableArray alloc] initWithCapacity:(stackSize + 1)];
        _activeRequests = [[NSMutableSet alloc] initWithCapacity:maxConcurrentDownloads];
        _originQueue = dispatch_get_current_queue();
        _callbackQueue = dispatch_get_current_queue();
    }
    
    return self;
}

#pragma mark - Enroll new requests

- (void)fetchImageAtURL:(NSURL *)url
      stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock
{
    [self fetchImageAtURL:url progressBlock:NULL stateChangedBlock:stateChangedBlock];
}

// This method needs a lot of love
- (void)fetchImageAtURL:(NSURL *)url
          progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
      stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock
{
    AXImageFetchRequest * request = [[AXImageFetchRequest alloc] initWithURL:url];
    if (request == nil) {
        return;
    }
    
    request.progressBlock = progressBlock;
    
    if (request.existsInCache) {
        request.stateChangedBlock = stateChangedBlock;
        [request quickLoad];
    }
    else {
        __weak AXImageFetchRequest * refRequest = request;
        request.stateChangedBlock = ^(AXImageFetchRequestState state, NSString * imagePath, NSError * error) {
            if (stateChangedBlock != NULL) {
                stateChangedBlock(state, imagePath, error);
            }
            
            if (state == AXImageFetchRequestStateCompleted ||
                state == AXImageFetchRequestStateError)
            {
                dispatch_async(_originQueue, ^{
                    [self completedActiveRequest:refRequest];
                });
            }
        };
        
        [_downloadStack addObject:request];
        [self pokeDownloadStack];
    }
}

#pragma mark - Download Stack Operations

- (NSUInteger)pendingDownloads
{
    return [_downloadStack count];
}

- (void)completedActiveRequest:(AXImageFetchRequest *)request
{
    [_activeRequests removeObject:request];
    [self pokeDownloadStack];
}

- (void)pokeDownloadStack
{
    // First, and always, trim the stack
    while ([_downloadStack count] > _stackSize + 1) {
        [_downloadStack removeObjectAtIndex:0];
    }
    
    // Fill up the request pool while there is room
    while ([_activeRequests count] < _maxConcurrentDownloads) {
        AXImageFetchRequest * nextRequest = [_downloadStack lastObject];
        if (nextRequest == nil) break;
        
        [_downloadStack removeLastObject];
        
        [_activeRequests addObject:nextRequest];
        [nextRequest start];
    }
}

@end
