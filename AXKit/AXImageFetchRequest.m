//
//  AXImageFetchRequest.m
//  AXKit
//
//  Created by James Savage on 12/9/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "AXImageFetchRequest.h"
#import "AXConstants.h"

NSInteger const kAXImageFetchRequestErrorNone = 0;
NSInteger const kAXImageFetchRequestErrorInvalidURL = 1;
NSInteger const kAXImageFetchRequestErrorCanceled = 2;
NSInteger const kAXImageFetchRequestErrorTemporaryFile = 3;
NSInteger const kAXImageFetchRequestErrorMovingIntoPlace = 4;
NSInteger const kAXImageFetchRequestErrorBadResposneCode = 5;
NSInteger const kAXImageFetchRequestErrorURLConnectionFailed = 6;

NSString * const kAXImageFetchRequestErrorImageURLKey = @"ImageURL";

#define AXImageFetchRequestCacheDirectory() [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.axiixc.AXKit.AXImageFetchRequest"]

#define CHANGE_STATE(state, error) do { \
_requestState = state; \
AX_DispatchAsyncOnQueue(_callbackQueue, _stateChangedBlock, state, _finalCachePath, error); \
} while(NO)

@interface AXImageFetchRequest ()
- (void)setStateDownloading;
- (void)setStateCompleted;
- (void)setStateErrorWithCode:(NSInteger)errorCode;
- (void)setStateErrorWithCode:(NSInteger)errorCode error:(NSError *)error;
@end

@implementation AXImageFetchRequest {
    NSURL * _imageURL;
    NSString * _tempCachePath;
    NSFileHandle * _tempFileHandle;
    
    NSURLConnection * _connection;
    long long _filesize;
}

#pragma mark - Property Synthesis

@synthesize progressBlock = _progressBlock;
@synthesize stateChangedBlock = _stateChangedBlock;
@synthesize callbackQueue = _callbackQueue;
@synthesize requestState = _requestState;
@synthesize requestErrorCode = _requestErrorCode;
@synthesize cachePath = _finalCachePath;

#pragma mark - Class Utility Methods

+ (BOOL)cacheContainsImageAtURL:(NSURL *)url
{
    if (url == nil) {
        return NO;
    }
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self cachePathForImageAtURL:url]];
}

+ (NSString *)cachePathForImageAtURL:(NSURL *)url
{
    if (url == nil) {
        return nil;
    }
    
    return [AXImageFetchRequestCacheDirectory() stringByAppendingPathComponent:
            [[[[url absoluteString]
               stringByReplacingOccurrencesOfString:@"%" withString:@"_"]
              stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
             stringByReplacingOccurrencesOfString:@":" withString:@"_"]];
}

+ (UIImage *)cachedImageAtPath:(NSString *)path
             fallbackImageName:(NSString *)fallbackImageName
{
    UIImage * image = [UIImage imageWithContentsOfFile:path];
    if (image == nil) {
        image = [UIImage imageNamed:fallbackImageName];
    }
    
    return image;
}

#pragma mark - Entrypoint Methods

+ (AXImageFetchRequest *)fetchImageAtURL:(NSURL *)url
                       stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock
{
    // Forward to general method
    return [self fetchImageAtURL:url progressBlock:NULL stateChangedBlock:stateChangedBlock];
}

+ (AXImageFetchRequest *)fetchImageAtURL:(NSURL *)url
                           progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
                       stateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock
{
    // Fast path, for images that already exist. This does
    // contain duplicated code, however it allows the class
    // methods to return without the object-creation overhead.
    if ([self cacheContainsImageAtURL:url]) {
        if (stateChangedBlock != NULL) {
            stateChangedBlock(AXImageFetchRequestStateCompleted, [self cachePathForImageAtURL:url], nil);
        }
        
        return nil;
    }
    
    // Using the standard request method
    AXImageFetchRequest * request = [[self alloc] initWithURL:url];
    
    if (request == nil) {
        NSError * error = [NSError errorWithDomain:kAXErrorDomain code:kAXImageFetchRequestErrorInvalidURL userInfo:nil];
        stateChangedBlock(AXImageFetchRequestStateError, nil, error);
    }
    else {
        request.progressBlock = progressBlock;
        request.stateChangedBlock = stateChangedBlock;
        [request start];
    }
    
    return request;
}

- (id)init
{
    NSAssert(NO, @"Must initialize with -initWithURL:");
    return nil;
}

- (id)initWithURL:(NSURL *)url
{
    if (url == nil) {
        return nil;
    }
    
    if ((self = [super init])) {
        _imageURL = url;
        _finalCachePath = [[self class] cachePathForImageAtURL:url];
        _callbackQueue = dispatch_get_current_queue();
        
        _requestErrorCode = kAXImageFetchRequestErrorNone;
        _requestState = AXImageFetchRequestStateNotStarted;
    }
    
    return self;
}

#pragma mark - Callback Control Flow

- (void)setStateChangedBlock:(AXImageFetchRequestStateChangedBlock)stateChangedBlock
{
    _stateChangedBlock = [stateChangedBlock copy];
    
    AX_DispatchSyncOnQueue(_callbackQueue, _stateChangedBlock, _requestState, _finalCachePath, nil);
}

#pragma mark - Control Flow

- (BOOL)existsInCache
{
    return [[self class] cacheContainsImageAtURL:_imageURL];
}

- (BOOL)quickLoad
{
    if (self.existsInCache && _requestState == AXImageFetchRequestStateNotStarted) {
        [self setStateCompleted];
        return YES;
    }
    
    return NO;
}

- (BOOL)start
{
    // If the request has already started, or the image exists
    // just drop out now.
    if (_requestState != AXImageFetchRequestStateNotStarted || [self quickLoad]) {
        return NO;
    }
    
    NSString * temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"XXXXXXXXXXXX"];
    const char * temporaryFileTemplateCString = [temporaryPath fileSystemRepresentation];
    char * temporaryFileNameCString = (char *) malloc(strlen(temporaryFileTemplateCString) + 1);
    strcpy(temporaryFileNameCString, temporaryFileTemplateCString);
    int fileDescriptor = mkstemp(temporaryFileNameCString);
    
    if (fileDescriptor == -1) {
        [self setStateErrorWithCode:kAXImageFetchRequestErrorTemporaryFile];
        return NO;
    }
    
    _tempCachePath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:temporaryFileNameCString length:strlen(temporaryFileNameCString)];
    _tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:NO];
    
    free(temporaryFileNameCString);
    
    [self setStateDownloading];
    
    NSURLRequest * request = [NSURLRequest requestWithURL:_imageURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    
    return YES;
}

- (void)cancel
{
    // This can only do something if the request is running
    if (_requestState != AXImageFetchRequestStateDownloading) {
        return;
    }
    
    [_connection cancel], _connection = nil;
    
    [self setStateErrorWithCode:kAXImageFetchRequestErrorCanceled];
}

#pragma mark - Download Logic (NSURLConnectionDelegate)

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode != 200) {
            [self setStateErrorWithCode:kAXImageFetchRequestErrorBadResposneCode];
        }
    }
    
    _filesize = [response expectedContentLength];
    AX_DispatchAsyncOnQueue(_callbackQueue, _progressBlock, 0, _filesize);
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    [_tempFileHandle writeData:data];
    
    long long downloaded = [_tempFileHandle offsetInFile];
    AX_DispatchAsyncOnQueue(_callbackQueue, _progressBlock, downloaded, _filesize);
}

#define CLOSE_TEMP_FILE() [_tempFileHandle closeFile], _tempFileHandle = nil
#define TRY_MOVE() error = nil; [[NSFileManager defaultManager] moveItemAtPath:_tempCachePath toPath:_finalCachePath error:&error]

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CLOSE_TEMP_FILE();
    
    NSError * error;
    TRY_MOVE();
    
    if (error.code == NSFileNoSuchFileError) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:AXImageFetchRequestCacheDirectory()])
        {
            NSError * makeDirError = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:AXImageFetchRequestCacheDirectory() withIntermediateDirectories:YES attributes:nil error:&makeDirError];
            if (!makeDirError) {
                TRY_MOVE();
            }
        }
    }
    else if (error.code == NSFileWriteFileExistsError) {
        NSError * removeOldError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:_finalCachePath error:&removeOldError];
        if (!removeOldError) {
            TRY_MOVE();
        }
    }
          
    if (error) {
        [self setStateErrorWithCode:kAXImageFetchRequestErrorMovingIntoPlace error:error];
    }
    else {
        [self setStateCompleted];
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    CLOSE_TEMP_FILE();
    
    [self setStateErrorWithCode:kAXImageFetchRequestErrorURLConnectionFailed error:error];
}

#pragma mark - Cleanup Methods

+ (BOOL)removeCachedImageAtURL:(NSURL *)url
{
    NSString * cachedPath = [self cachePathForImageAtURL:url];
    
    NSError * error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:&error];
    
    return (error != nil);
}

+ (BOOL)removeAllCachedImages
{
    NSError * error = nil;
    __block BOOL hasError = NO;
    
    NSArray * directoryListing = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AXImageFetchRequestCacheDirectory() error:&error];
    if (!error) {
        [directoryListing enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSError * delError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:[AXImageFetchRequestCacheDirectory() stringByAppendingPathComponent:obj] error:&delError];
            hasError |= (delError != nil);
        }];
    }
    
    return (error != nil) | hasError;
}
                                   
#pragma mark - Private helper methods

- (void)setStateDownloading
{
    // A request can only initiate a download once per instance
    if (_requestState == AXImageFetchRequestStateDownloading) {
        return;
    }
    
    CHANGE_STATE(AXImageFetchRequestStateDownloading, nil);
}

- (void)setStateCompleted
{
    // A request can only complete once per instance
    if (_requestState == AXImageFetchRequestStateCompleted) {
        return;
    }
    
    CHANGE_STATE(AXImageFetchRequestStateCompleted, nil);
}

- (void)setStateErrorWithCode:(NSInteger)errorCode
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:_imageURL forKey:kAXImageFetchRequestErrorImageURLKey];
    NSError * error = [NSError errorWithDomain:kAXErrorDomain code:errorCode userInfo:userInfo];
    
    [self setStateErrorWithCode:errorCode error:error];
}

- (void)setStateErrorWithCode:(NSInteger)errorCode error:(NSError *)error
{
    // Only handle one error per instance
    if (_requestState == AXImageFetchRequestStateError) {
        return;
    }
    
    _requestState = AXImageFetchRequestStateError;
    _requestErrorCode = errorCode;
    
    AX_DispatchSyncOnQueue(_callbackQueue, _stateChangedBlock, _requestState, nil, error);
}

@end
