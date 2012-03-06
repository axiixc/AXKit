//
//  SUIWebView.h
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AXWebView;

@interface SUIWebView : UIViewController

@property (strong, nonatomic) IBOutlet AXWebView * webView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem * hideKeyboardButton;

- (IBAction)hideKeyboard;

@end
