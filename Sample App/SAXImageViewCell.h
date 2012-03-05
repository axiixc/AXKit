//
//  SAXImageViewCell.h
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AXImageFetchRequestStack;

@interface SAXImageViewCell : UITableViewCell

- (id)initWithRequestStack:(AXImageFetchRequestStack *)stack
           reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic) NSURL * imageURL;

@end
