//
//  AXImageCache.h
//  AXKit
//
//  Created by James Savage on 12/9/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

/* This class can be used for processing a large number of image
 * downloads. It uses a fixed-size stack to ensure that only so
 * many downloads are pending at any given time, throwing out
 * older downloads if enough new requests are made.
 *
 * Internally it uses AXImageFetchRequest instances, the API of
 * which are exposed by the `-fetchImage...' methods. For more
 * information on behavior refer to AXImageFetchRequest's docs.
 */
@interface AXImageCache : NSObject

- (id)initWithDownloadStackSize:(NSInteger)stackSize;

- (void)fetchImageAtURL:(NSURL *)url
        completionBlock:(id)completionBlock;
- (void)fetchImageAtURL:(NSURL *)url
        completionBlock:(id)completionBlock
          progressBlock:(id)progressBlock;

@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, readonly) NSInteger pendingDownloadCount;

@end
