//
//  SUIWebView.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "SUIWebView.h"
#import "UIWebView+AXExtendedAppearance.h"

@implementation SUIWebView

@synthesize webView = _webView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.webView makeCustomAppearance_ax:AXWebViewAppearanceOptionsAll];
    [self.webView loadHTMLString:@"<h1>Custom Web View</h1>"
                                 @"<input type='text' placeholder='text field' />"
                                 @"<input type='email' placeholder='another text field' />"
                         baseURL:nil];
}

@end
