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

NSString * const kAXImageFetchRequestErrorImageURLKey = @"imageURL";

#define AXImageFetchRequestCacheDirectory() [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.axiixc.AXKit.AXImageFetchRequest"]

@interface AXImageFetchRequest ()
- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode;
- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode error:(NSError *)error;
@end

@implementation AXImageFetchRequest {
    NSURL * _imageURL;
    NSString * _finalCachePath;
    NSString * _tempCachePath;
    NSFileHandle * _tempFileHandle;
    
    NSURLConnection * _connection;
    long long _filesize;
    
    dispatch_once_t _hasCalledCompletionBlock;
}

#pragma mark - Property Synthesis

@synthesize progressBlock = _progressBlock;
@synthesize completionBlock = _completionBlock;
@synthesize callbackQueue = _callbackQueue;
@synthesize requestState = _requestState;
@synthesize requestErrorCode = _requestErrorCode;

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
            [[[url absoluteString]
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
                         completionBlock:(AXImageFetchRequestCompletionBlock)completionBlock
{
    // This method is simply a forward
    return [self fetchImageAtURL:url
                   progressBlock:NULL
                 completionBlock:completionBlock];
}

+ (AXImageFetchRequest *)fetchImageAtURL:(NSURL *)url
                           progressBlock:(AXImageFetchRequestProgressBlock)progressBlock
                         completionBlock:(AXImageFetchRequestCompletionBlock)completionBlock
{
    // Fast path, for images that already exist
    if ([self cacheContainsImageAtURL:url]) {
        AX_DispatchAsyncOnQueue(dispatch_get_current_queue(), completionBlock, [self cachePathForImageAtURL:url], nil);
        return nil;
    }
    
    // Using the standard request method
    AXImageFetchRequest * request = [[self alloc] initWithURL:url];
    
    if (request == nil) {
        NSError * error = [NSError errorWithDomain:kAXErrorDomain code:kAXImageFetchRequestErrorInvalidURL userInfo:nil];
        AX_DispatchAsyncOnQueue(dispatch_get_current_queue(), completionBlock, nil, error);
    }
    else {
        request.progressBlock = progressBlock;
        request.completionBlock = completionBlock;
        [request start];
    }
    
    return request;
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

#pragma mark - Control Flow

- (BOOL)start
{
    if (_requestState == AXImageFetchRequestStateError) {
        [self callCompletionBlockForErrorCode:_requestErrorCode];
    }
    
    if (_requestState != AXImageFetchRequestStateNotStarted) {
        return NO;
    }
    
    NSString * temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"XXXXXXXXXXXX"];
    const char * temporaryFileTemplateCString = [temporaryPath fileSystemRepresentation];
    char * temporaryFileNameCString = (char *) malloc(strlen(temporaryFileTemplateCString) + 1);
    strcpy(temporaryFileNameCString, temporaryFileTemplateCString);
    int fileDescriptor = mkstemp(temporaryFileNameCString);
    
    if (fileDescriptor == -1) {
        [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorTemporaryFile];
        return NO;
    }
    
    _tempCachePath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:temporaryFileNameCString length:strlen(temporaryFileNameCString)];
    _tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:NO];
    
    free(temporaryFileNameCString);
    
    NSURLRequest * request = [NSURLRequest requestWithURL:_imageURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    
    return YES;
}

- (void)cancel
{
    // This can only do something if the request is running
    if (_requestState != AXImageFetchRequestStateStarted) {
        return;
    }
    
    [_connection cancel], _connection = nil;
    
    [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorCanceled];
}

#pragma mark - Download Logic (NSURLConnectionDelegate)

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode != 200) {
            [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorBadResposneCode];
        }
    }
    
    NSLog(@"Response: %@", response);
    
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
#define TRY_MOVE() [[NSFileManager defaultManager] moveItemAtPath:_tempCachePath toPath:_finalCachePath error:&error]

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finish");
    CLOSE_TEMP_FILE();
    
    NSError * error = nil;
    TRY_MOVE();
    if (error.code == NSFileNoSuchFileError) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:AXImageFetchRequestCacheDirectory()])
        {
            NSError * makeDirError = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:AXImageFetchRequestCacheDirectory() withIntermediateDirectories:YES attributes:nil error:&makeDirError];
            if (!makeDirError) {
                error = nil;
                TRY_MOVE();
            }
        }
    }
          
    if (error) {
        [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorMovingIntoPlace error:error];
    }
    else {
        _requestState = AXImageFetchRequestStateCompleted;
        AX_DispatchAsyncOnQueue(_callbackQueue, _completionBlock, _finalCachePath, nil);
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    CLOSE_TEMP_FILE();
    
    [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorURLConnectionFailed error:error];
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

- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:_imageURL forKey:kAXImageFetchRequestErrorImageURLKey];
    NSError * error = [NSError errorWithDomain:kAXErrorDomain code:errorCode userInfo:userInfo];
    
    [self callCompletionBlockForErrorCode:errorCode error:error];
}

- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode error:(NSError *)error
{
    _requestState = AXImageFetchRequestStateError;
    _requestErrorCode = errorCode;
    
    dispatch_once(&_hasCalledCompletionBlock, ^{
        AX_DispatchAsyncOnQueue(_callbackQueue, _completionBlock, nil, error);
    });
}

@end
