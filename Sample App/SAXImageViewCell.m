//
//  SAXImageViewCell.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "SAXImageViewCell.h"
#import "AXImageView.h"
#import "AXImageFetchRequestStack.h"

@implementation SAXImageViewCell {
    AXImageView * axImageView;
    AXImageFetchRequestStack * axImageFetchRequestStack;
}

- (id)initWithRequestStack:(AXImageFetchRequestStack *)stack
             reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]))
    {
        axImageFetchRequestStack = stack;
        
        axImageView = [AXImageView new];
        axImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        axImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:axImageView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    axImageView.frame = self.contentView.bounds;
}

- (void)setImageURL:(NSURL *)imageURL
{
    [axImageView setImageAtURL:imageURL
             usingRequestStack:axImageFetchRequestStack
           withCompletionBlock:NULL];
}

- (NSURL *)imageURL
{
    return [axImageView imageURL];
}

@end
