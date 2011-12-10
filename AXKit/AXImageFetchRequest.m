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
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self cachePathForImageAtURL:url] isDirectory:NO];
}

+ (NSString *)cachePathForImageAtURL:(NSURL *)url
{
    if (url == nil) {
        return nil;
    }
    
    return [NSTemporaryDirectory() stringByAppendingString:
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
        if (completionBlock != NULL) {
            completionBlock([self cachePathForImageAtURL:url], nil);
        }
        
        return nil;
    }
    
    // Using the standard request method
    AXImageFetchRequest * request = [[self alloc] initWithURL:url];
    
    if (request == nil && completionBlock != NULL) {
        NSError * error = [NSError errorWithDomain:kAXErrorDomain code:kAXImageFetchRequestErrorInvalidURL userInfo:nil];
        completionBlock(nil, error);
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
    
    NSString * temporaryPath = [_finalCachePath stringByAppendingPathExtension:@"XXXXXX"];
    const char * temporaryFileTemplateCString = [temporaryPath fileSystemRepresentation];
    char * temporaryFileNameCString = (char *) malloc(strlen(temporaryFileTemplateCString) + 1);
    strcpy(temporaryFileNameCString, temporaryFileTemplateCString);
    int fileDescriptor = mkstemp(temporaryFileNameCString);
    
    if (fileDescriptor == -1) {
        [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorTemporaryFile];
    }
    
    _tempCachePath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:temporaryFileNameCString length:strlen(temporaryFileNameCString)];
    _tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:NO];
    
    free(temporaryFileNameCString);
    
    NSURLRequest * request = [NSURLRequest requestWithURL:_imageURL];
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
    
    _filesize = [response expectedContentLength];
    AX_DispatchSyncOnQueue(_callbackQueue, _progressBlock, 0, _filesize);
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    [_tempFileHandle writeData:data];
    AX_DispatchSyncOnQueue(_callbackQueue, _progressBlock, [_tempFileHandle offsetInFile], _filesize);
}

#define CLOSE_TEMP_FILE() [_tempFileHandle closeFile], _tempFileHandle = nil

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CLOSE_TEMP_FILE();
    
    NSError * error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:_tempCachePath toPath:_finalCachePath error:&error];
    
    if (error) {
        [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorMovingIntoPlace error:error];
    }
    else {
        _requestState = AXImageFetchRequestStateCompleted;
        AX_DispatchSyncOnQueue(_callbackQueue, _completionBlock, _finalCachePath, nil);
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    CLOSE_TEMP_FILE();
    
    [self callCompletionBlockForErrorCode:kAXImageFetchRequestErrorURLConnectionFailed error:error];
}
                                   
#pragma mark - Private helper methods

- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:_imageURL forKey:kAXImageFetchRequestErrorImageURLKey];
    NSError * error = [NSError errorWithDomain:kAXErrorDomain code:_requestErrorCode userInfo:userInfo];
    
    [self callCompletionBlockForErrorCode:errorCode error:error];
}

- (void)callCompletionBlockForErrorCode:(NSInteger)errorCode error:(NSError *)error
{
    _requestState = AXImageFetchRequestStateError;
    _requestErrorCode = errorCode;
    
    dispatch_once(&_hasCalledCompletionBlock, ^{
        AX_DispatchSyncOnQueue(_callbackQueue, _completionBlock, nil, error);
    });
}

@end
