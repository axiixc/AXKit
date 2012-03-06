//
//  SUIWebView.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "SUIWebView.h"
#import "AXWebView.h"

@implementation SUIWebView

@synthesize webView = _webView;
@synthesize hideKeyboardButton = _hideKeyboardButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.webView makeCustomAppearance_ax:AXWebViewAppearanceOptionsAll];
    [self.webView setInputAccessoryView:nil];
    [self.webView loadHTMLString:@"<h1>Custom Web View</h1>"
                                 @"<input type='text' placeholder='text field' />"
                                 @"<input type='email' placeholder='another text field' />"
                         baseURL:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardDidShowNotification:) 
     name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillHideNotification:)
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardDidShowNotification:(NSNotification *)note
{
    // Get the size of the keyboard.
    NSDictionary * info = [note userInfo];
    NSValue * aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    self.webView.frame = (CGRect){ CGPointZero,
        { self.view.bounds.size.width , self.view.bounds.size.height - keyboardSize.height }};
    self.hideKeyboardButton.enabled = YES;
}

- (void)keyboardWillHideNotification:(NSNotification *)note
{
    self.webView.frame = self.view.bounds;
    self.hideKeyboardButton.enabled = NO;
}

- (void)hideKeyboard
{
    [self.webView dismissKeyboard];
}

@end
