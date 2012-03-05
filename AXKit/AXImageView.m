//
//  UIImage+AXRemoteImages.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "AXImageView.h"
#import "AXConstants.h"
#import "AXImageFetchRequestStack.h"
#import <objc/runtime.h>

@interface AXImageView ()

+ (AXImageFetchRequestStack *)defaultFetchRequestStack_ax;

@property (strong, nonatomic, readwrite) NSURL * imageURL;
@property (nonatomic, readwrite) BOOL placeholderActive;

@end

static AXImageFetchRequestStack * defaultFetchRequestStack = nil;

@implementation AXImageView

+ (AXImageFetchRequestStack *)defaultFetchRequestStack_ax
{
    if (defaultFetchRequestStack == nil)
        defaultFetchRequestStack = [[AXImageFetchRequestStack alloc] 
                                    initWithStackSize:kAXImageFetchRequestStackSizeUnlimited
                                    maxConcurrentDownloads:2];
    
    return defaultFetchRequestStack;
}

@synthesize callbackBlock = _callbackBlock;
@synthesize imageURL = _imageURL;
@synthesize placeholderImage = _placeholderImage;
@synthesize placeholderView = _placeholderView;
@synthesize placeholderActive = _placeholderActive;

- (void)setImage:(UIImage *)image
{
    self.callbackBlock = nil;
    self.imageURL = nil;
    
    [super setImage:image];
}

- (void)setImageAtURL:(NSURL *)url
{
    [self setImageAtURL:url
      usingRequestStack:[[self class] defaultFetchRequestStack_ax]
    withCompletionBlock:NULL];
}

- (void)setImageAtURL:(NSURL *)url
  withCompletionBlock:(AXRemoteImagesCallbackBlock)callbackBlock
{
    [self setImageAtURL:url
      usingRequestStack:[[self class] defaultFetchRequestStack_ax]
    withCompletionBlock:NULL];
}

- (void)setImageAtURL:(NSURL *)url
    usingRequestStack:(AXImageFetchRequestStack *)stack
  withCompletionBlock:(AXRemoteImagesCallbackBlock)callbackBlock
{
    self.imageURL = url;
    self.callbackBlock = callbackBlock;
    
    [stack
     fetchImageAtURL:url
     stateChangedBlock:^(AXImageFetchRequestState state, NSString *imagePath, NSError *error)
     {
         // Only invoke if the completed image is the current URL
         if (![imagePath isEqualToString:[AXImageFetchRequest cachePathForImageAtURL:self.imageURL]])
             return;
         
         switch (state) {
             case AXImageFetchRequestStateCompleted:
             {
                 if (_callbackBlock != NULL)
                     _callbackBlock(nil);
                 
                 UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
                 if (image == nil)
                 {
                     [self setPlaceholderActive:YES];
                 }
                 else
                 {
                     [self setPlaceholderActive:NO];
                     [super setImage:image];
                 }
                 break;
             }
                 
             case AXImageFetchRequestStateError:
             {
                 if (_callbackBlock != NULL)
                     _callbackBlock(error);
             }
                 
             default:
             {
                 [self setPlaceholderActive:YES];
                 break;
             }
         }
     }];
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    BOOL placeholderState = _placeholderActive;
    [self setPlaceholderActive:NO];
    
    if (_placeholderView) _placeholderView = nil;
    _placeholderImage = placeholderImage;
    
    [self setPlaceholderActive:placeholderState];
}

- (void)setPlaceholderView:(UIView *)placeholderView
{
    BOOL placeholderState = _placeholderActive;
    [self setPlaceholderActive:NO];
    
    if (_placeholderImage) _placeholderImage = nil;
    _placeholderView = placeholderView;
    
    [self setPlaceholderActive:placeholderState];
}

- (void)setPlaceholderActive:(BOOL)active
{
    _placeholderActive = active;
    
    if (active && _placeholderImage)
    {
        [super setImage:_placeholderImage];
    }
    else if (active && _placeholderView)
    {
        if ([_placeholderView superview] != self)
        {
            _placeholderView.frame = self.bounds;
            _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            [self addSubview:_placeholderView];
        }
    }
    else if (active)
    {
        [super setImage:nil];
    }
    else if (!active && _placeholderImage)
    {
        [super setImage:nil];
    }
    else if (!active && _placeholderView)
    {
        [_placeholderView removeFromSuperview];
    }
}

@end
