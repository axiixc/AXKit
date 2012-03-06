//
//  AXWebView.m
//  AXKit
//
//  Created by James Savage on 3/5/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "AXWebView.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>

@interface UIWebBrowserView : UIView
@end

@interface UIWebBrowserView (PleaseDontHateMeApple)

- (void)setUseCustomInputAccessoryView_ax:(BOOL)useCustomAcessoryView;
- (BOOL)useCustomInputAccessoryView_ax;

- (void)setCustomInputAccessoryView_ax:(UIView *)view;
- (UIView *)customInputAccessoryView_ax;

@end

@implementation UIWebBrowserView (PleaseDontHateMeApple)

static char kAXWebBrowserViewUseCustomAcessoryViewKey;
static char kAXWebBrowserViewCustomAccessoryViewKey;

- (UIView *)inputAccessoryViewWithSupportForOverrides_ax
{
    return (self.useCustomInputAccessoryView_ax) ? self.customInputAccessoryView_ax : [self inputAccessoryViewWithSupportForOverrides_ax];
}

- (void)setUseCustomInputAccessoryView_ax:(BOOL)useCustomAcessoryView
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError * error;
        [UIWebBrowserView jr_swizzleMethod:@selector(inputAccessoryView) withMethod:@selector(customInputAccessoryView_ax) error:&error];
        
        // TODO: Make more effective
        if (error) {
            NSLog(@"%@", error);
        }
    });
    
    if (self.useCustomInputAccessoryView_ax == useCustomAcessoryView) return;
    
    objc_setAssociatedObject(self, 
                             &kAXWebBrowserViewUseCustomAcessoryViewKey, 
                             [NSNumber numberWithBool:useCustomAcessoryView], 
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)useCustomInputAccessoryView_ax
{
    NSNumber * useCustomAcessoryView = objc_getAssociatedObject(self, &kAXWebBrowserViewUseCustomAcessoryViewKey);
    return (useCustomAcessoryView) ? [useCustomAcessoryView boolValue] : NO;
}

- (void)setCustomInputAccessoryView_ax:(UIView *)view
{
    objc_setAssociatedObject(self, 
                             &kAXWebBrowserViewCustomAccessoryViewKey, 
                             view, 
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)customInputAccessoryView_ax
{
    return objc_getAssociatedObject(self, &kAXWebBrowserViewCustomAccessoryViewKey);
}

@end

@implementation AXWebView

- (UIView *)getWebBrowserView
{
    UIView * scroller = [self.subviews objectAtIndex:0];
    for (UIView * subview in scroller.subviews)
        if ([subview.class.description isEqualToString:@"UIWebBrowserView"])
            return subview;
    return nil;
}

- (UIView *)inputAccessoryView
{
    return [[self getWebBrowserView] inputAccessoryView];
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView
{
    UIWebBrowserView * browserView = (UIWebBrowserView *)[self getWebBrowserView];
    [browserView setUseCustomInputAccessoryView_ax:YES];
    [browserView setCustomInputAccessoryView_ax:inputAccessoryView];
}

- (void)setDefaultInputAccessoryView
{
    UIWebBrowserView * browserView = (UIWebBrowserView *)[self getWebBrowserView];
    [browserView setUseCustomInputAccessoryView_ax:NO];
}

- (void)dismissKeyboard
{
    UIWebBrowserView * browserView = (UIWebBrowserView *)[self getWebBrowserView];
    [browserView resignFirstResponder];
}

@end