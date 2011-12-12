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
 * older downloads if enough new requests are made. Downloads
 * within the cache will occur in serial, with only one download
 * active at a time.
 *
 * Internally it uses AXImageFetchRequest instances, the API of
 * which are exposed by the `-fetchImage...' methods. For more
 * information on behavior refer to AXImageFetchRequest's docs.
 *
 * The image cache class offers its own `callbackQueue' proeprty.
 * This queue will be set as the `callbackQueue' of the request
 * immediately before starting the request. As such, changing it
 * will only affect requests that have not yet been started. Thus
 * it is recommended that if you need a custom queue, you set it
 * before you begin adding requests.
 *
 * THIS CLASS IS INTENDED TO BE THREAD-SAFE, HOWEVER IN ITS
 * CURRENT FORM IT IS NOT. IT HAS ONLY BEEN TESTED FOR CREATION
 * ON THE MAIN QUEUE, WITH THE MAIN QUEUE AS ITS CALLBACK QUEUE.
 */

#import "AXImageFetchRequest.h"

@interface AXImageCache : NSObject

- (id)initWithDownloadStackSize:(NSInteger)stackSize;

- (void)fetchImageAtURL:(NSURL *)url
        completionBlock:(AXImageFetchRequestStateChangedBlock)completionBlock;
- (void)fetchImageAtURL:(NSURL *)url
          startingBlock:(AXImageFetchRequestStartingBlock)startingBlock
          progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
        completionBlock:(AXImageFetchRequestStateChangedBlock)completionBlock;

- (void)cancelAll;

@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, readonly) NSInteger pendingDownloadCount;
@property (nonatomic) NSInteger stackSize;

@end
