//
//  AXImageFetchRequest.h
//  AXKit
//
//  Created by James Savage on 12/9/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

/* This class serves as both an internal component of the
 * AXImageCache class and a standalone image download class.
 *
 * It provides an asynchronyous mechanism for downloading
 * and caching image resources. It can be considered threadsafe
 * in as much as it may be started from any thread, however
 * it will schedule the network request in the main run loop.
 *
 * Callbacks, given as blocks, will by default be invoked from
 * the queue on which the request was initialized, however this
 * may be overriden by setting the `callbackQueue' property
 * after initialization.
 *
 * The completion block serves as the primary callback interface
 * and will be invoked regardless of how the request terminates.
 * If an error preventing download has occured it will be called
 * with a nil cached image path, and a non-nil error, otherwise
 * it will have an appropriate path and a nil error. While it is
 * not technically necessary to supply a completion block, there
 * is no other way to tell once a download has finished.
 *
 * The progress block may be called two or more times during the
 * download of the resource. Once upon start with zero completion
 * and once when the download finishes with full completion. 
 * Completion is given as two values, the currently download size
 * and the total download size.
 *
 * Images can be fetched using one of two method families:
 * 
 * `+fetchImageAtURL:...'
 *      This method will create, and automatically start, a
 * AXImageFetchRequest. This method will either return the
 * created request, or nil if the image already exists in the
 * cache, or if the request could not be created. In either of
 * these cases the completion block will be invoked as if the
 * request ran normally.
 *
 * `-initWithURL:'
 *      By using the default initialzier you can specify
 * additional information, such as the callback queue. You will
 * also have to manually set the completion and progress blocks,
 * and start the request. This method will only return nil if it
 * is given a nil URL. If the requested image already exists the
 * completion block will not be triggered until `-start' is 
 * called.
 *
 * During download the image will be stored to a temporary file
 * and moved into place at the end. It is possible for multiple
 * fetches of the same resouce to occur simultaneously. In this
 * situation the file will be downloaded multiple times to
 * multiple unique temporary files, with each being moved into
 * place and overwriting the previous upon its completion.
 * Of course, if the cached file already exists a download will
 * not be spawned.
 *
 * Images may be purged from the cache through via the
 *      + (BOOL)removeCachedImageAtURL:(NSURL *)url
 *      + (BOOL)removeAllCachedImages
 * methods. Additonally a standard filesystem delete can be used
 * to remove an image. The class does not retain any metadata
 * about fully cached images in memory, so there is no explict
 * need to use the framework for deletes. Additionally it is safe
 * to delete the cache subdirectory, however it is probably
 * better not to, since it will just have to be remade.
 */

typedef void (^AXImageFetchRequestProgressBlock)(long long downloaded, long long filesize);

typedef void (^AXImageFetchRequestCompletionBlock)(NSString * imagePath, NSError * error);

typedef enum {
    /* The request is waiting to be started */
    AXImageFetchRequestStateNotStarted,
    /* The request is currently downloading */
    AXImageFetchRequestStateStarted,
    /* The request has completed sucessfully */
    AXImageFetchRequestStateCompleted,
    /* The request was stopped before completion by an error */
    AXImageFetchRequestStateError,
} AXImageFetchRequestState;

/* No error occured */
extern NSInteger const kAXImageFetchRequestErrorNone;
/* The supplied URL was nil */
extern NSInteger const kAXImageFetchRequestErrorInvalidURL;
/* The request was programatically canceled */
extern NSInteger const kAXImageFetchRequestErrorCanceled;
/* Could not create a temporary download file */
extern NSInteger const kAXImageFetchRequestErrorTemporaryFile;
/* Could not move the temporary file into place. The supplied
 * error object in the completion block will be the error from
 * the NSFileManager.
 */
extern NSInteger const kAXImageFetchRequestErrorMovingIntoPlace;
/* Recieved a response code other than 200 */
extern NSInteger const kAXImageFetchRequestErrorBadResposneCode;
/* The URL Connection invoked its failure delegate method. The
 * error object in the completion block will be the error from
 * the NSURLConnection.
 */
extern NSInteger const kAXImageFetchRequestErrorURLConnectionFailed;

/* Key for the original URL of the image request, for NSError
 * objects passed to the completionBlock with non-nil userinfo.
 */
extern NSString * const kAXImageFetchRequestErrorImageURLKey;

@interface AXImageFetchRequest : NSObject

/* This method returns YES if a image at the specified URL has
 * been completely downloaded and cached.
 */
+ (BOOL)cacheContainsImageAtURL:(NSURL *)url;

/* This method creates a local path from a URL, which will point
 * to where an image at the specified URL would be stored after
 * it has been downloaded. Note: a file may not exist at this
 * path, so it should be checked before trying to read from.
 */
+ (NSString *)cachePathForImageAtURL:(NSURL *)url;

/* This method is intended for user from within a completion
 * callback block to avoid repetition of nil checking the cache
 * path. It will check if the supplied path is nil or invalid,
 * returning the image specified by `fallbackImageName' from
 * the app bundle if true. Otherwise it will return the cached
 * image using [UIImage imageWithContentsOfFile:]. If you wish
 * to have more control over how the image is loaded, you should
 * not use this method.
 */
+ (UIImage *)cachedImageAtPath:(NSString *)path
             fallbackImageName:(NSString *)fallbackImageName;

/* These method are defined above */
+ (AXImageFetchRequest *)fetchImageAtURL:(NSURL *)url
                         completionBlock:(AXImageFetchRequestCompletionBlock)completionBlock;
+ (AXImageFetchRequest *)fetchImageAtURL:(NSURL *)url
                           progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
                         completionBlock:(AXImageFetchRequestCompletionBlock)completionBlock;
- (id)initWithURL:(NSURL *)url;

/* Begin the download of this image. Once this method has been
 * called, the request may not be restarted. The return value
 * indicates if the request was sucessfully started.
 */
- (BOOL)start;

/* Abort the download of this image. Deleting any resources
 * already created. Once this has been called the request may not
 * be restarted.
 */
- (void)cancel;

/* These properties are described above */
@property (nonatomic, copy) AXImageFetchRequestProgressBlock progressBlock;
@property (nonatomic, copy) AXImageFetchRequestCompletionBlock completionBlock;
@property (nonatomic) dispatch_queue_t callbackQueue;

/* The current state of the request */
@property (nonatomic, readonly) AXImageFetchRequestState requestState;

/* This will only be set to a non-zero value if `requestState`
 * is AXImageFetchRequestStateError.
 */
@property (nonatomic, readonly) NSInteger requestErrorCode;

/* These methods are described above */
+ (BOOL)removeCachedImageAtURL:(NSURL *)url;
+ (BOOL)removeAllCachedImages;

@end
