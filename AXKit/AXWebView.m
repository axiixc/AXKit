//
//  AXWebView.m
//  AXKit
//
//  Created by James Savage on 3/5/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "AXWebView.h"
#import "AXConstants.h"

#ifdef AX_PRIVATE_API
#import "JRSwizzle.h"
#import <objc/runtime.h>

@interface UIWebBrowserView : UIView
@end

@interface UIWebBrowserView (PleaseDontHateMeApple)
@end

@implementation UIWebBrowserView (PleaseDontHateMeApple)

- (AXWebView *)parentWebView_ax
{
    UIView * superview = [self superview];
    while (superview != nil && ![superview.class.description isEqualToString:@"AXWebView"])
        superview = [superview superview];
    return (AXWebView *)superview;
}

- (UIView *)customInputAccessoryView_ax
{
    AXWebView * parentWebView = self.parentWebView_ax;
    return ([parentWebView shouldOverrideWebDocumentViewInputAcessoryView_ax]) ?
    [parentWebView inputAccessoryView] : [self customInputAccessoryView_ax];
}

- (BOOL)customCanPerformAction_ax:(SEL)action withSender:(id)sender
{
    AXWebView * parentWebView = self.parentWebView_ax;
    
    if (!parentWebView)
        return [self customCanPerformAction_ax:action withSender:sender];
    
    int overrideValue = [parentWebView canPerformWebDocumentViewAction_ax:action withSender:sender];
    if (overrideValue < 0) return NO;
    if (overrideValue > 0) return YES;
    else return [self customCanPerformAction_ax:action withSender:sender];
}

@end
#endif

@implementation AXWebView

#ifdef AX_PRIVATE_API
@synthesize inputAccessoryView;
@synthesize useDefaultWhenInputAccessoryViewNil_ax;

- (UIView *)getWebBrowserView
{
    UIView * scroller = [self.subviews objectAtIndex:0];
    for (UIView * subview in scroller.subviews)
        if ([subview.class.description isEqualToString:@"UIWebBrowserView"])
            return subview;
    return nil;
}

- (void)dismissKeyboard
{
    UIWebBrowserView * browserView = (UIWebBrowserView *)[self getWebBrowserView];
    [browserView resignFirstResponder];
}

- (BOOL)shouldOverrideWebDocumentViewInputAcessoryView_ax
{
    return (!self.useDefaultWhenInputAccessoryViewNil_ax || self.inputAccessoryView != nil);
}

- (int)canPerformWebDocumentViewAction_ax:(SEL)action withSender:(id)sender
{
    return 0;
}

- (void)setup_ax
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError * error;
        [UIWebBrowserView
         jr_swizzleMethod:@selector(inputAccessoryView)
         withMethod:@selector(customInputAccessoryView_ax)
         error:&error];
        
        if (error) {
            NSLog(@"AXWebView: Error swizzeling inputAccessoryView methods.\n%@", error);
        }
        
        [UIWebBrowserView
         jr_swizzleMethod:@selector(canPerformAction:withSender:)
         withMethod:@selector(customCanPerformAction_ax:withSender:)
         error:&error];
        
        if (error) {
            NSLog(@"AXWebView: Error swizzeling canPerformAction:withSender:.\n%@", error);
        }
    });
}

- (id)init
{
    if ((self = [super init]))
        [self setup_ax];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
        [self setup_ax];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
        [self setup_ax];
    return self;
}
#endif

@end