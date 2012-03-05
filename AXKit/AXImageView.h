//
//  UIImage+AXRemoteImages.h
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AXImageFetchRequestStack;

typedef void(^AXRemoteImagesCallbackBlock)(NSError * error);

@interface AXImageView : UIImageView

- (void)setImageAtURL:(NSURL *)url;
- (void)setImageAtURL:(NSURL *)url
  withCompletionBlock:(AXRemoteImagesCallbackBlock)callbackBlock;
- (void)setImageAtURL:(NSURL *)url
    usingRequestStack:(AXImageFetchRequestStack *)stack
  withCompletionBlock:(AXRemoteImagesCallbackBlock)callbackBlock;

@property (copy, nonatomic) AXRemoteImagesCallbackBlock callbackBlock;
@property (strong, nonatomic, readonly) NSURL * imageURL;

@property (strong, nonatomic) UIImage * placeholderImage;
@property (strong, nonatomic) UIView * placeholderView;
@property (nonatomic, readonly) BOOL placeholderActive;

@end
