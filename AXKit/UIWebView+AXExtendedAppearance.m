//
//  UIWebView+AXExtendedAppearance.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "UIWebView+AXExtendedAppearance.h"

@implementation UIWebView (AXExtendedAppearance)

- (void)createCustomAppearance:(AXWebViewAppearanceOptions)options
{
    if (options & AXWebViewAppearanceRemoveShadows)
    {
        id scroller = [self.subviews objectAtIndex:0];
        for (UIView * subView in [scroller subviews])
            if ([[[subView class] description] isEqualToString:@"UIImageView"])
                subView.hidden = YES;
    }
    
    if (options & AXWebViewAppearanceTransparent)
    {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    
    if (options & AXWebViewAppearanceDiscardKeyboardAccessoryView)
    {
        // TODO: not yet implemented
    }
}

@end
