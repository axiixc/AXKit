//
//  AXWebView.h
//  AXKit
//
//  Created by James Savage on 3/5/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AXWebView : UIWebView

#ifdef AX_PRIVATE_API
@property (readwrite) UIView * inputAccessoryView;
- (void)dismissKeyboard;

- (void)setDefaultInputAccessoryView;
#endif

@end
