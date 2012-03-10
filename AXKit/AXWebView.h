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
@property (strong, readwrite) UIView * inputAccessoryView;
@property (assign, readwrite) BOOL useDefaultWhenInputAccessoryViewNil_ax;
- (void)dismissKeyboard;
#endif

@end

#ifdef AX_PRIVATE_API
@interface AXWebView (CanOverrideInSubclasses)
- (BOOL)shouldOverrideWebDocumentViewInputAcessoryView_ax;

// (< 0) NO
// (= 0) DEFAULT
// (> 0) YES
- (int)canPerformWebDocumentViewAction_ax:(SEL)action withSender:(id)sender;
@end
#endif