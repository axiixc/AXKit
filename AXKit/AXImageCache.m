//
//  AXImageCache.m
//  AXKit
//
//  Created by James Savage on 12/9/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

// TODO: This really needs better thread-safety!

#import "AXImageCache.h"

@interface AXImageCache ()
- (void)clearActiveRequest;
- (void)popDownloadStack;
@end

@implementation AXImageCache {
    NSMutableArray * _pendingDownloads;
    AXImageFetchRequest * _activeRequest;
    
    // This is used to synchronize all stack mutations to the
    // instanciation queue.
    dispatch_queue_t _internalQueue;
}

#pragma mark - Property Synthesis

@synthesize callbackQueue = _callbackQueue;
@synthesize stackSize = _stackSize;

#pragma mark - Initialization

- (id)init
{
    if ((self = [super init])) {
        _pendingDownloads = [NSMutableArray new];
        _stackSize = 10;
        _callbackQueue = dispatch_get_current_queue();
        _internalQueue = dispatch_get_current_queue();
    }
    
    return self;
}

- (id)initWithDownloadStackSize:(NSInteger)stackSize
{
    if ((self = [self init])) {
        _stackSize = stackSize;
    }
    
    return self;
}

#pragma mark - Adding Image Fetches

- (void)fetchImageAtURL:(NSURL *)url
        completionBlock:(AXImageFetchRequestStateChangedBlock)completionBlock
{
    [self fetchImageAtURL:url startingBlock:nil progressBlock:nil completionBlock:completionBlock];
}

- (void)fetchImageAtURL:(NSURL *)url 
          startingBlock:(AXImageFetchRequestStartingBlock)startingBlock
          progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
        completionBlock:(AXImageFetchRequestStateChangedBlock)completionBlock
{
    AXImageFetchRequest * request = [[AXImageFetchRequest alloc] initWithURL:url];
    if (request != nil) {
        request.startingBlock = startingBlock;
        request.progressBlock = progressBlock;
        
        // Try a fast-path. Use the provided completion block
        // verbaitm if possible, otherwise wrap it.
        if ([request existsInCache]) {
            request.completionBlock = completionBlock;
            [request quickLoad];
            
            return;
        }
        else {
            request.completionBlock = ^(NSString * imagePath, NSError * error) {
                dispatch_async(_internalQueue, ^{
                    [self clearActiveRequest];
                    [self popDownloadStack];
                });
                
                if (completionBlock != NULL) {
                    completionBlock(imagePath, error);
                }
            };
            
            [_pendingDownloads insertObject:request atIndex:0];
            [self popDownloadStack];
        }
    }
}

- (void)cancelAll
{
    [self clearActiveRequest];
    [_pendingDownloads removeAllObjects];
}

#pragma mark - Pending download count

- (NSInteger)pendingDownloadCount
{
    return [_pendingDownloads count];
}

#pragma mark - Internal Logic

- (void)clearActiveRequest
{
    [_activeRequest cancel], _activeRequest = nil;
}

- (void)popDownloadStack
{
    // Trim the stack
    while (self.pendingDownloadCount > _stackSize) {
        [_pendingDownloads removeLastObject];
    }
    
    // If no pending operations, or one is running!
    if (!self.pendingDownloadCount || _activeRequest) {
        return;
    }
    
    // TODO: Find a better stack mechanic
    _activeRequest = [_pendingDownloads objectAtIndex:0];
    [_pendingDownloads removeObjectAtIndex:0];
    
    [_activeRequest start];
}

@end