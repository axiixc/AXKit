//
//  UIWebView+AXExtendedAppearance.h
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    AXWebViewAppearanceRemoveShadows = 1 << 0,
    AXWebViewAppearanceTransparent = 1 << 1,
    AXWebViewAppearanceDiscardKeyboardAccessoryView = 1 << 2,
} AXWebViewAppearanceOptions;

#define AXWebViewAppearanceOptionsAll (AXWebViewAppearanceRemoveShadows|AXWebViewAppearanceTransparent|AXWebViewAppearanceDiscardKeyboardAccessoryView)

@interface UIWebView (AXExtendedAppearance)

- (void)createCustomAppearance:(AXWebViewAppearanceOptions)options;

@end
